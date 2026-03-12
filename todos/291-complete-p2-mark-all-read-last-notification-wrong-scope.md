---
status: pending
priority: p2
issue_id: "291"
tags: [code-review, rails, notifications, bug]
dependencies: []
---

# mark_all_read sets @last_notification from unread scope — should be overall newest

## Problem Statement
In `NotificationsController#mark_all_read`, `@last_notification` is assigned as the first element of `@notifications`, which is scoped to `.unread` only. After marking all read, the `@last_notification` is the most-recently-created notification that was previously unread — but the nav bell partial likely needs the overall newest notification (read or unread) for its timestamp/preview. The `mark_read` action correctly issues a fresh `Current.user.notifications.newest_first.first` query; `mark_all_read` should do the same.

## Findings
**File:** `app/controllers/notifications_controller.rb`

```ruby
def mark_all_read
  @notifications     = Current.user.notifications.unread.newest_first.to_a
  @last_notification = @notifications.first  # BUG: unread scope only
  ...
end
```

Compare with `mark_read` which correctly does:
```ruby
@last_notification = Current.user.notifications.newest_first.first
```

## Proposed Solutions

### Option A — Issue fresh query (matches mark_read pattern)
```ruby
@last_notification = Current.user.notifications.newest_first.first
```
**Pros:** Consistent with `mark_read`. Always returns overall newest regardless of read state. **Effort:** Trivial. **Risk:** None.

## Recommended Action

## Technical Details
- **File:** `app/controllers/notifications_controller.rb` — `mark_all_read` action

## Acceptance Criteria
- [ ] `@last_notification` in `mark_all_read` is assigned via `Current.user.notifications.newest_first.first` (fresh query, not scoped to unread)
- [ ] Controller test asserts `@last_notification` is the overall newest notification after mark_all_read

## Work Log
- 2026-03-12: Code review finding — kieran-rails-reviewer

## Resources
- Branch: dev
