---
status: complete
priority: p2
issue_id: "330"
tags: [code-review, notifications, correctness, medications]
dependencies: []
---

# Low-Stock Notification Suppressed After Refill — `exists?` Guard Missing `read: false`

## Problem Statement

`app/models/notification.rb#create_low_stock_for` checks `exists?` to prevent duplicate low-stock notifications. However, the `exists?` guard does not filter by `read: false`. When a user acknowledges (reads) a low-stock notification, then refills their medication, and later the medication becomes low-stock again, the `exists?` check finds the old (read) notification and suppresses the new one. The user never gets re-notified about the new low-stock condition.

## Findings

**Flagged by:** architecture-strategist (rated MODERATE)

```ruby
# app/models/notification.rb:27 (approx)
def self.create_low_stock_for(medication)
  return if exists?(notifiable: medication, notification_type: :low_stock)  # BUG: includes read notifications
  create!(notifiable: medication, notification_type: :low_stock, ...)
end
```

Fix:
```ruby
return if exists?(notifiable: medication, notification_type: :low_stock, read: false)
```

Or alternatively, clear old low-stock notifications for a medication on refill.

## Proposed Solutions

### Option A: Add `read: false` to the `exists?` guard (Recommended)
```ruby
return if exists?(notifiable: medication, notification_type: :low_stock, read: false)
```

**Pros:** Simple, correct — only suppresses if an unread notification already exists
**Cons:** None
**Effort:** Tiny
**Risk:** None

### Option B: Delete old low-stock notifications on refill
In the `refill` action, destroy any existing low-stock notifications for the medication.

```ruby
# settings/medications_controller.rb#refill
@medication.notifications.where(notification_type: :low_stock).destroy_all
```

**Pros:** Cleaner notification history; clears stale alerts
**Cons:** User loses the history of the notification
**Effort:** Small
**Risk:** Low

### Recommended Action

Option A is the minimal correct fix. Option B can be combined as a UX improvement.

## Technical Details

- **File:** `app/models/notification.rb`, `create_low_stock_for` class method
- The `read` boolean column exists on notifications

## Acceptance Criteria

- [ ] After reading a low-stock notification + refilling + becoming low-stock again, a new notification is created
- [ ] Duplicate unread low-stock notifications are still suppressed
- [ ] Notification tests cover the refill + re-notify scenario

## Work Log

- 2026-03-12: Created from Milestone 2 code review — architecture-strategist MODERATE finding
