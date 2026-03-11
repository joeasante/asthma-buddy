---
status: pending
priority: p1
issue_id: "258"
tags: [code-review, security, rails, database]
dependencies: []
---

# TOCTOU Race Condition in Notification Deduplication

## Problem Statement

The deduplication pattern in `Notification.create_low_stock_for` and `MissedDoseCheckJob` uses a check-then-act sequence (`exists?` followed by `create!`) without a database unique constraint or surrounding transaction. Two concurrent `DoseLog` saves for the same medication — for example, a rapid double-tap on the Log Dose button, or an `after_create_commit` callback and a background job both firing in close succession — can both pass the `exists?` guard and both reach `create!`, inserting duplicate unread notifications for the same event. In a medical context, spurious duplicate alerts erode user trust and may cause alert fatigue.

## Findings

`app/models/notification.rb` lines 21–33:

```ruby
def self.create_low_stock_for(medication)
  return if exists?(
    user: medication.user,
    notifiable: medication,
    notification_type: "low_stock",
    read: false
  )
  create!(
    user: medication.user,
    notifiable: medication,
    notification_type: "low_stock"
  )
end
```

`app/jobs/missed_dose_check_job.rb` lines 26–29:

```ruby
unless Notification.exists?(user: user, notifiable: medication, notification_type: "missed_dose", read: false)
  Notification.create!(user: user, notifiable: medication, notification_type: "missed_dose")
end
```

Both sites share the same structural flaw: `exists?` and `create!` are not atomic. Without a unique index, the database cannot enforce the deduplication invariant that the application code assumes.

Confirmed by: kieran-rails-reviewer, security-reviewer.

## Proposed Solutions

### Option A — Add a partial unique index + rescue RecordNotUnique *(Recommended)*

**Migration:**

```ruby
add_index :notifications,
          [:user_id, :notifiable_type, :notifiable_id, :notification_type],
          where: "read = 0",
          unique: true,
          name: "index_notifications_unique_unread_per_notifiable"
```

**Model:**

```ruby
def self.create_low_stock_for(medication)
  create!(
    user: medication.user,
    notifiable: medication,
    notification_type: "low_stock"
  )
rescue ActiveRecord::RecordNotUnique
  # Duplicate suppressed — another process already created this notification
end
```

**Job:**

```ruby
begin
  Notification.create!(user: user, notifiable: medication, notification_type: "missed_dose")
rescue ActiveRecord::RecordNotUnique
  # Duplicate suppressed
end
```

Pros: atomically enforced at the DB layer; `RecordNotUnique` rescue is the correct place to handle this, not `exists?`; removes the race window entirely
Cons: requires a migration; partial index syntax is SQLite-compatible (`where:` clause supported since SQLite 3.8.9)

### Option B — Wrap in a transaction with a row-level lock

Use `with_lock` or `SELECT FOR UPDATE` to serialise the check and insert.

Pros: no schema change required
Cons: heavier than necessary; SQLite does not support `SELECT FOR UPDATE` — this is a SQLite-backed app

### Option C — Use `find_or_create_by` with `rescue`

```ruby
Notification.find_or_create_by!(user: ..., notifiable: ..., notification_type: ..., read: false)
rescue ActiveRecord::RecordNotUnique
  # no-op
end
```

Pros: idiomatic Rails
Cons: still has a race window without a unique index; only safe when combined with Option A's index

## Recommended Action

Option A — add the partial unique index and replace `exists?/create!` pairs with a bare `create!` wrapped in `rescue ActiveRecord::RecordNotUnique`. This is the only approach that eliminates the race at the database level.

## Technical Details

- **Affected files:**
  - `app/models/notification.rb` lines 21–33
  - `app/jobs/missed_dose_check_job.rb` lines 26–29
  - New migration required

## Acceptance Criteria

- [ ] Migration adds `index_notifications_unique_unread_per_notifiable` partial unique index
- [ ] `create_low_stock_for` removes `exists?` guard and rescues `ActiveRecord::RecordNotUnique`
- [ ] `MissedDoseCheckJob` removes `exists?` guard and rescues `ActiveRecord::RecordNotUnique`
- [ ] Concurrent calls to `create_low_stock_for` for the same medication produce exactly one unread notification
- [ ] Model test added: calling `create_low_stock_for` twice rapidly does not create duplicate notifications
- [ ] Job test added: running `MissedDoseCheckJob` twice for the same user/medication does not create duplicate notifications
- [ ] `bin/rails db:migrate` runs without error

## Work Log

- 2026-03-11: Found by kieran-rails-reviewer and security-reviewer during Phase 19 code review
