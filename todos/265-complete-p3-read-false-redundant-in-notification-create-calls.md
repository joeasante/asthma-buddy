---
status: pending
priority: p3
issue_id: "265"
tags: [code-review, rails, cleanup]
dependencies: []
---

# `read: false` Redundant in All `Notification.create!` Calls (DB Default)

## Problem Statement

Every `Notification.create!` call in the codebase passes `read: false` explicitly. The notifications migration sets `default: false` on the `read` column, so the database handles this value automatically when it is omitted. The explicit keyword is redundant noise that adds nothing and slightly obscures intent by implying it needs to be passed.

## Findings

`app/models/notification.rb` line 31:

```ruby
Notification.create!(
  user: user,
  notification_type: :low_stock,
  notifiable: medication,
  read: false   # redundant — DB default: false
)
```

`app/jobs/missed_dose_check_job.rb` line 39:

```ruby
Notification.create!(
  user: user,
  notification_type: :missed_dose,
  notifiable: dose_log,
  read: false   # redundant — DB default: false
)
```

The migration that establishes the default:

```ruby
t.boolean :read, default: false, null: false
```

Confirmed by: kieran-rails-reviewer.

## Proposed Solutions

### Option A — Remove `read: false` from all `Notification.create!` calls *(Recommended)*

```ruby
# app/models/notification.rb
Notification.create!(
  user: user,
  notification_type: :low_stock,
  notifiable: medication
)

# app/jobs/missed_dose_check_job.rb
Notification.create!(
  user: user,
  notification_type: :missed_dose,
  notifiable: dose_log
)
```

Pros: removes noise; relying on DB defaults is idiomatic Rails; fewer keywords to read
Cons: none — behaviour is identical

## Recommended Action

Option A — remove `read: false` from both `create!` call sites.

## Technical Details

- **Affected files:**
  - `app/models/notification.rb` line 31
  - `app/jobs/missed_dose_check_job.rb` line 39

## Acceptance Criteria

- [ ] Neither `Notification.create!` call site passes `read: false`
- [ ] New notifications are still created with `read = false`
- [ ] Existing model and job tests continue to pass

## Work Log

- 2026-03-11: Found by kieran-rails-reviewer during Phase 19 code review
