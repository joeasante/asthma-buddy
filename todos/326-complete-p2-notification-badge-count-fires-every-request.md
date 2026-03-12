---
status: complete
priority: p2
issue_id: "326"
tags: [code-review, performance, notifications, n-plus-one]
dependencies: []
---

# `set_notification_badge_count` Fires on Every Authenticated Request

## Problem Statement

`app/controllers/application_controller.rb` runs `set_notification_badge_count` as a `before_action` on every authenticated request. This fires a `COUNT` SQL query on the notifications table for every page load across the entire app. Additionally, `NotificationsController` actions also compute the badge count separately (to update the badge after marking notifications read), resulting in duplicate queries on those pages.

For a user who visits the app frequently, this is one extra SQL query per request with no caching.

## Findings

**Flagged by:** performance-oracle

- `ApplicationController#set_notification_badge_count`: runs on every authenticated action
- `NotificationsController`: also queries badge count to update the Turbo stream after mark_read actions
- No caching on the count query
- Potential for 2x queries on notification-related pages

## Proposed Solutions

### Option A: HTTP cache / etag on badge count
Cache the count in the Rails cache store (Solid Cache) with a short TTL (e.g. 30 seconds), invalidated when a notification is created or marked read.

```ruby
def set_notification_badge_count
  @unread_notification_count = Rails.cache.fetch(
    "notification_badge/#{Current.user.id}",
    expires_in: 30.seconds
  ) { Current.user.notifications.unread.count }
end
```

Invalidate in `Notification.after_commit`.

**Pros:** Near-zero DB cost for the badge; staleness is acceptable (30s)
**Cons:** Cache invalidation logic; slight staleness
**Effort:** Small-Medium
**Risk:** Low

### Option B: Skip in `NotificationsController` (Quick win)
Since `NotificationsController` already updates the badge via Turbo stream after mark_read, skip the before_action there:

```ruby
# notifications_controller.rb
skip_before_action :set_notification_badge_count
```

And compute it inline only where needed.

**Pros:** Eliminates the duplicate immediately
**Cons:** Doesn't address the per-request overhead globally
**Effort:** Tiny
**Risk:** None

### Option C: Move badge count to a Turbo Frame
Render the badge count in a `<turbo-frame>` that lazy-loads via a separate endpoint. Badge only refreshes when the frame is visible or explicitly targeted.

**Pros:** Zero overhead on non-notification pages
**Cons:** Requires new endpoint + Turbo frame; more complex
**Effort:** Medium
**Risk:** Low

### Recommended Action

Option B as an immediate fix (skip in NotificationsController). Option A as a follow-up improvement.

## Technical Details

- **File:** `app/controllers/application_controller.rb`
- Notifications badge is in `app/views/layouts/_nav_bell.html.erb`

## Acceptance Criteria

- [ ] No duplicate badge count queries on notification pages
- [ ] Badge count query is either cached or reduced in frequency
- [ ] Badge still updates correctly after marking notifications read

## Work Log

- 2026-03-12: Created from Milestone 2 code review — performance-oracle finding
