---
phase: 22-request-path-caching
plan: 03
subsystem: caching
tags: [rails, cache, notifications, badge, turbo-stream]

requires:
  - phase: 22-request-path-caching/22-01
    provides: "Badge count cache key unread_notifications/{user_id} established in ApplicationController#set_notification_badge_count"
  - phase: 22-request-path-caching/22-02
    provides: "Dashboard vars cache pattern with explicit invalidation callbacks"

provides:
  - "NotificationsController#mark_all_read explicitly deletes the badge cache key after update_all"
  - "MarkAllReadCacheInvalidationTest proving cache key is nil after mark_all_read and repopulated on next request"

affects:
  - 22-request-path-caching

tech-stack:
  added: []
  patterns:
    - "Explicit Rails.cache.delete after update_all: update_all bypasses AR callbacks, so any cache key dependent on those records must be manually invalidated at the call site"

key-files:
  created: []
  modified:
    - app/controllers/notifications_controller.rb
    - test/controllers/notifications_controller_test.rb

key-decisions:
  - "update_all bypass requires explicit cache invalidation: update_all skips all AR lifecycle callbacks including after_commit; the badge cache key must be deleted at the controller call site immediately after update_all"
  - "Cache key deleted (not written to 0): mark_all_read deletes the key so the next request recomputes from DB via fetch, rather than caching a hardcoded 0 that might go stale"

patterns-established:
  - "Explicit cache delete at update_all call site: whenever update_all is used in a context where an associated cache key exists, add Rails.cache.delete immediately after"

duration: 5min
completed: 2026-03-13
---

# Phase 22 Plan 03: Mark All Read Cache Invalidation Summary

**Explicit Rails.cache.delete after update_all in mark_all_read closes UAT gap — badge no longer reappears after marking all notifications read**

## Performance

- **Duration:** ~5 min
- **Completed:** 2026-03-13
- **Tasks:** 2 of 2
- **Files modified:** 2

## Accomplishments

- Added `Rails.cache.delete("unread_notifications/#{Current.user.id}")` after `update_all` in `NotificationsController#mark_all_read` — closes the stale-cache bug where the badge reappeared on subsequent page loads
- Added `MarkAllReadCacheInvalidationTest` proving the cache key is `nil` (deleted) after `mark_all_read`, and repopulated with `0` on the next dashboard request
- Full test suite remains green: 516 tests, 0 failures, 0 errors (up from 515 — one new test added)

## Task Commits

1. **Task 1: Explicit cache invalidation in mark_all_read** - `017e5a4` (fix)
2. **Task 2: MarkAllReadCacheInvalidationTest** - `c8a944c` (test)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `app/controllers/notifications_controller.rb` — Added `Rails.cache.delete` line after `update_all` in `mark_all_read`
- `test/controllers/notifications_controller_test.rb` — Appended `MarkAllReadCacheInvalidationTest` top-level class with 1 test

## Decisions Made

- **update_all bypass requires explicit invalidation:** `update_all` skips all AR callbacks including `after_commit`. The badge cache key established in Plan 22-01 is never invalidated by the existing `Notification#invalidate_badge_cache` callback when `mark_all_read` runs. Fix is a single `Rails.cache.delete` at the controller call site.
- **Cache key deleted, not written to 0:** `mark_all_read` deletes the key rather than writing `0`, so the next request uses `fetch` to recompute from DB — this preserves the single-source-of-truth pattern established in 22-01 and avoids a cached `0` going stale if something else creates notifications concurrently.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 22 UAT gap closed: "Badge on bell icon stays gone after marking all notifications as read" is now confirmed fixed
- Phase 22 (request-path caching) is complete: badge count cached (22-01), dashboard vars cached (22-02), mark_all_read invalidation fixed (22-03)

---
*Phase: 22-request-path-caching*
*Completed: 2026-03-13*
