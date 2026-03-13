---
phase: 22-request-path-caching
plan: 01
subsystem: caching
tags: [rails, solid-cache, rails-cache, notifications, badge-count, after_commit]

# Dependency graph
requires:
  - phase: 19-notifications
    provides: Notification model with unread scope, badge count before_action in ApplicationController
provides:
  - Cache-backed badge count via Rails.cache.fetch in ApplicationController#set_notification_badge_count
  - Cache invalidation on Notification create and mark-as-read via after_commit lambdas
  - Fix for Rails after_commit deduplication bug affecting Notification, DoseLog, and HealthEvent
affects:
  - Any phase adding Notification mutations (must use lambda callbacks)
  - 22-02-dashboard-vars-caching (same lambda pattern)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Rails.cache.fetch with per-user key (unread_notifications/{user_id}) and 1h TTL"
    - "after_commit lambda wrapping to avoid Rails symbol-based callback deduplication"
    - "use_transactional_tests = false in nested test class with explicit teardown for after_commit testing"

key-files:
  created: []
  modified:
    - app/controllers/application_controller.rb
    - app/models/notification.rb
    - app/models/dose_log.rb
    - app/models/health_event.rb
    - test/models/notification_test.rb
    - test/controllers/notifications_controller_test.rb

key-decisions:
  - "Lambda callbacks (after_commit -> { method }) instead of symbol callbacks to bypass Rails deduplication of same-named commit callbacks across create/update/destroy"
  - "use_transactional_tests = false with explicit ensure/teardown restore in CacheInvalidationTest — after_create_commit/after_update_commit only fire when transaction actually commits"
  - "user_id FK integer used directly in invalidate_badge_cache — no association load, no N+1 risk"

patterns-established:
  - "Cache key pattern: {entity_type}/{user_id}/{optional_date_or_qualifier}"
  - "Lambda commit callbacks: after_commit -> { method }, on: :create to register multiple callbacks on the same model for the same action"
  - "CacheInvalidationTest nested class with use_transactional_tests = false for testing commit callbacks"

# Metrics
duration: 5min
completed: 2026-03-13
---

# Phase 22 Plan 01: Badge Count Cache Summary

**Solid Cache-backed unread notification badge count via Rails.cache.fetch with per-user 1h TTL, invalidated on create and mark-as-read via lambda after_commit callbacks**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-13T07:18:30Z
- **Completed:** 2026-03-13T07:23:10Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- `ApplicationController#set_notification_badge_count` now reads from `Rails.cache` under `unread_notifications/{user_id}` with 1h TTL — no DB hit on warm cache
- `Notification` model invalidates that key on create and on mark-as-read via lambda `after_commit` callbacks
- Updates to fields other than `read` do NOT clear the cache (guarded by `if: :saved_change_to_read?`)
- 4 new cache tests added (3 model, 1 integration), full suite green at 515 tests

## Task Commits

1. **Task 1: Cache badge count in ApplicationController and invalidate from Notification model** - `9709362` (feat)
2. **Task 2: Tests — cache written, served from cache, invalidated on create and mark-as-read** - `83db3fe` (test)

## Files Created/Modified
- `app/controllers/application_controller.rb` — `set_notification_badge_count` wrapped in `Rails.cache.fetch`
- `app/models/notification.rb` — `after_commit` lambda callbacks + `invalidate_badge_cache` private method; switched to lambda pattern
- `app/models/dose_log.rb` — Bug fix: lambda callbacks to replace deduplicated `after_create_commit`/`after_destroy_commit` symbol callbacks
- `app/models/health_event.rb` — Bug fix: lambda callbacks to replace deduplicated `after_create_commit`/`after_update_commit`/`after_destroy_commit` symbol callbacks
- `test/models/notification_test.rb` — Added `CacheInvalidationTest` nested class with 3 cache tests
- `test/controllers/notifications_controller_test.rb` — Added `BadgeCacheTest` subclass with 1 integration cache test

## Decisions Made
- **Lambda callbacks instead of symbol callbacks:** Rails deduplicates `_commit_callbacks` by filter. When the same method name (e.g. `:invalidate_badge_cache`) is registered via `after_create_commit` and `after_update_commit`, only the last declaration survives. Using `after_commit -> { method }, on: :create` creates a unique Proc object for each registration, bypassing deduplication.
- **`use_transactional_tests = false` in nested test class:** `after_create_commit` only fires when the DB transaction commits. In Rails' default test mode (transactional), the transaction is never committed — callbacks never run. Disabling transactional tests in the nested class allows the commit to happen, with explicit teardown cleaning up created records.
- **Direct `user_id` in callback:** `invalidate_badge_cache` uses `user_id` (the FK integer already loaded) rather than `user.id` — avoids an association load in the callback, keeping it a single cache delete with no DB query.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Rails after_commit callback deduplication in Notification, DoseLog, HealthEvent**
- **Found during:** Task 2 (writing cache invalidation tests)
- **Issue:** Rails deduplicates `_commit_callbacks` by filter symbol. `after_create_commit :invalidate_badge_cache` followed by `after_update_commit :invalidate_badge_cache` (or `after_destroy_commit`) with the same method name registers only ONE callback (the last one). The create/update callbacks never fired. This was present in the 22-02 commit for DoseLog and HealthEvent, and introduced in Task 1 for Notification.
- **Fix:** Replaced symbol-form callbacks with lambda wrappers: `after_commit -> { method }, on: :create`. Each lambda is a unique Proc object — no deduplication occurs.
- **Files modified:** `app/models/notification.rb`, `app/models/dose_log.rb`, `app/models/health_event.rb`
- **Verification:** 515 tests pass (previously 3 failing in DoseLog/HealthEvent cache tests); runners confirmed callbacks fire correctly
- **Committed in:** `83db3fe` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Critical correctness fix — without this, cache invalidation on create and update never executed, making the badge count cache stale indefinitely after the first write. No scope creep.

## Issues Encountered
- Rails `after_create_commit :method` and `after_update_commit :method` (or `after_destroy_commit :method`) with the same method name are silently deduplicated in `_commit_callbacks`. This is a known Rails behaviour where using symbol filters as keys means only the last registration wins. The fix (lambda wrappers) is the canonical solution.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Badge count cache is live; `set_notification_badge_count` queries the DB only on cache miss (first request per user or after invalidation)
- Cache invalidation wired correctly for all notification mutations (create, mark-as-read)
- Lambda callback pattern established — 22-02 dashboard vars plan should use the same pattern for any additional models

## Self-Check: PASSED

All files created/modified confirmed present. All task commits (9709362, 83db3fe) confirmed in git log.

---
*Phase: 22-request-path-caching*
*Completed: 2026-03-13*
