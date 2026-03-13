---
status: pending
priority: p3
issue_id: "340"
tags: [code-review, caching, cleanup, rails]
dependencies: ["337", "339"]
---

# Phase 22 caching minor cleanup batch

## Problem Statement

Several small code-quality and consistency issues identified in the Phase 22 code review. None are correctness bugs; all are readability or style improvements.

## Findings

### 1. Unnecessary `user_id` local variable in `set_notification_badge_count`
**File:** `app/controllers/application_controller.rb:33`
```ruby
user_id = Current.user.id   # ← unnecessary local
@unread_notification_count = Rails.cache.fetch("unread_notifications/#{user_id}", ...)
```
`Current.user.id` can be used inline. The local variable adds nothing and is inconsistent with every other method in this file.

### 2. `NotificationTest::CacheInvalidationTest` should be a top-level class
**File:** `test/models/notification_test.rb:184`
`CacheInvalidationTest` is nested inside `NotificationTest`. The rationale for `DoseLogDashboardCacheTest` and `HealthEventDashboardCacheTest` being top-level is that `self.use_transactional_tests = false` on a nested class may not propagate correctly in Rails 8's parallel test runner. The same reasoning applies here. Rename to `NotificationBadgeCacheTest` (top-level) to be consistent with the other four cache test classes.

### 3. `HealthEvent` three after_commit lines can be collapsed to array form
**File:** `app/models/health_event.rb:45-47`
```ruby
after_commit -> { invalidate_dashboard_cache }, on: :create
after_commit -> { invalidate_dashboard_cache }, on: :update
after_commit -> { invalidate_dashboard_cache }, on: :destroy
```
Rails accepts an array: `after_commit :invalidate_dashboard_cache, on: %i[create update destroy]`
Note: this requires using symbol form `:invalidate_dashboard_cache` rather than a lambda — which is fine here since HealthEvent only has one `invalidate_dashboard_cache` callback (no deduplication risk).

### 4. Add `race_condition_ttl` to dashboard_vars fetch
**File:** `app/controllers/concerns/dashboard_variables.rb:16`
```ruby
Rails.cache.fetch("...", expires_in: 5.minutes, race_condition_ttl: 10.seconds)
```
Prevents simultaneous cache misses from triggering parallel DB queries (cache stampede). Free to add, no behavior change for single-user traffic.

### 5. Add explanatory comment to `mark_all_read` explicit cache delete
**File:** `app/controllers/notifications_controller.rb:50`
```ruby
Current.user.notifications.unread.update_all(read: true)
# update_all bypasses AR callbacks — manually invalidate badge cache here
Rails.cache.delete("unread_notifications/#{Current.user.id}")
```
Without the comment a future reader may assume the line is redundant with the model callback and remove it.

### 6. `HealthEvent` private method indentation inconsistent
**File:** `app/models/health_event.rb` — the `private` keyword is at two-space indent but private methods (`invalidate_dashboard_cache`, `ended_at_after_recorded_at`) are also at two-space indent, making them visually indistinguishable from public methods. Should be indented to four spaces (matching `DoseLog` and `Notification` style).

## Proposed Solutions

Fix all items in a single small commit. Each is a one-or-two-line change.

## Acceptance Criteria

- [ ] `user_id` local variable removed from `set_notification_badge_count`
- [ ] `NotificationTest::CacheInvalidationTest` promoted to top-level `NotificationBadgeCacheTest`
- [ ] `HealthEvent` three `after_commit` lines collapsed (or left as-is if symbol form causes deduplication concern — confirm first)
- [ ] `race_condition_ttl: 10.seconds` added to dashboard_vars fetch
- [ ] Explanatory comment added above `mark_all_read` cache delete
- [ ] `HealthEvent` private method indentation corrected
- [ ] Full test suite passes

## Work Log

- 2026-03-13: Identified in Phase 22 code review (kieran-rails-reviewer, pattern-recognition-specialist, performance-oracle)
