---
status: pending
priority: p3
issue_id: "268"
tags: [code-review, performance, database]
dependencies: []
---

# Missing Composite Deduplication Index on `notifications` Table

## Problem Statement

`Notification.exists?` is called with a 5-field predicate (`user_id`, `notification_type`, `notifiable_type`, `notifiable_id`, `read`) in two hot paths: on every `DoseLog` save (via an `after_save` callback) and on every iteration of `MissedDoseCheckJob`. The existing index on `[user_id, read]` narrows results to a user's unread rows but then performs a sequential scan of that subset to match `notifiable_type`, `notifiable_id`, and `notification_type`. A covering composite index turns these deduplication checks into pure index lookups.

## Findings

`app/models/notification.rb` (deduplication guard):

```ruby
Notification.exists?(
  user: user,
  notification_type: :low_stock,
  notifiable: medication,
  read: false
)
```

`app/jobs/missed_dose_check_job.rb` (deduplication guard):

```ruby
Notification.exists?(
  user: user,
  notification_type: :missed_dose,
  notifiable: dose_log,
  read: false
)
```

Current indexes on `notifications` (from `db/schema.rb`):

```ruby
add_index :notifications, [:user_id, :read]
```

This index covers the first two predicates. The remaining three columns (`notification_type`, `notifiable_type`, `notifiable_id`) are not indexed, so SQLite must scan filtered rows to evaluate the full predicate.

For applications with many notifications per user, and with `MissedDoseCheckJob` iterating over potentially large sets of dose logs, this scan grows linearly. A composite index covering all five columns makes the `exists?` check O(log n).

Additionally, if `unique: true` is added to this index it would enforce deduplication at the database level and partially address the TOCTOU race documented in todo 258.

Confirmed by: kieran-rails-reviewer.

## Proposed Solutions

### Option A — Add a composite covering index *(Recommended)*

New migration:

```ruby
class AddDeduplicationIndexToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_index :notifications,
              %i[user_id notification_type notifiable_type notifiable_id read],
              name: "index_notifications_deduplication"
  end
end
```

Pros: pure index lookup for all `exists?` deduplication checks; no application code changes needed
Cons: minor write overhead on insert (acceptable — notifications are written infrequently)

### Option B — Add the index with `unique: true`

```ruby
add_index :notifications,
          %i[user_id notification_type notifiable_type notifiable_id read],
          unique: true,
          name: "index_notifications_deduplication"
```

Pros: enforces deduplication at the DB layer, eliminating the TOCTOU window; guards against future code paths that skip the `exists?` guard
Cons: requires existing data to be free of duplicates before the migration runs; a duplicate-clearing step may be needed; `read: true` rows would also be part of the unique key which may need adjustment

## Recommended Action

Option A first — add the non-unique composite index to fix the performance issue. Evaluate Option B separately once the TOCTOU todo (258) is addressed, as that work will clarify the correct uniqueness semantics.

## Technical Details

- **Affected file:** new migration in `db/migrate/`

## Acceptance Criteria

- [ ] A migration exists that adds `index_notifications_deduplication` on `[user_id, notification_type, notifiable_type, notifiable_id, read]`
- [ ] `db/schema.rb` reflects the new index
- [ ] `bin/rails db:migrate` runs cleanly with no errors
- [ ] `Notification.exists?` queries in model and job use the new index (verifiable via `EXPLAIN QUERY PLAN`)
- [ ] All existing notification tests continue to pass

## Work Log

- 2026-03-11: Found by kieran-rails-reviewer during Phase 19 code review
