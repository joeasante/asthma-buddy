---
phase: 22-request-path-caching
plan: 02
subsystem: database
tags: [rails, solid-cache, caching, activerecord, callbacks, dashboard]

# Dependency graph
requires:
  - phase: 22-request-path-caching
    provides: Badge count caching plan (22-01) — establishes Solid Cache as active caching layer
provides:
  - Cache-backed set_dashboard_vars with 5-minute TTL and midnight rotation
  - DoseLog invalidation callbacks (create, destroy)
  - HealthEvent invalidation callbacks (create, update, destroy)
  - 7 cache tests covering population and write-triggered invalidation
affects: [dashboard, settings-base-controller, dose-logging, health-events]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Rails.cache.fetch with user-scoped Date.current key for daily-rotating dashboard data"
    - "after_commit on: :create / :destroy for write-triggered cache invalidation from models"
    - "Top-level test class with use_transactional_tests = false for after_commit callback testing"

key-files:
  created: []
  modified:
    - app/controllers/concerns/dashboard_variables.rb
    - app/models/dose_log.rb
    - app/models/health_event.rb
    - test/models/dose_log_test.rb
    - test/models/health_event_test.rb
    - test/controllers/dashboard_controller_test.rb

key-decisions:
  - "Top-level test class required for use_transactional_tests = false — nested class declarations inside an outer TestCase class do not properly propagate the setting in Rails 8 parallelized test runner"
  - "after_commit -> { method }, on: :create style enforced by RuboCop omakase over after_create_commit :method shorthand"
  - "Sentinel cache overwrite pattern verifies cache read-path: first request populates, manually set sentinel, second request returns sentinel unchanged"
  - "use puffs: 99 sentinel value in DoseLog teardown cleanup to avoid colliding with fixture records"

patterns-established:
  - "Cache invalidation test pattern: top-level class + use_transactional_tests = false + MemoryStore in setup + NullStore restore in teardown + delete_all cleanup of non-transactional records"

# Metrics
duration: 12min
completed: 2026-03-13
---

# Phase 22 Plan 02: Dashboard Vars Caching Summary

**Rails.cache.fetch wraps set_dashboard_vars with a per-user Date.current key; DoseLog and HealthEvent after_commit callbacks delete the key on every write, giving zero-stale dashboard data with Solid Cache backing**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-03-13T10:38:34Z
- **Completed:** 2026-03-13T10:50:30Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- `DashboardVariables#set_dashboard_vars` now fetches from `Rails.cache` under key `dashboard_vars/{user_id}/{Date.current}` with 5-minute TTL
- `DoseLog` invalidates the cache key on create and destroy commit callbacks
- `HealthEvent` invalidates the cache key on create, update, and destroy commit callbacks
- 7 new cache tests covering population and write-triggered invalidation from both models plus dashboard integration
- Full suite green: 515 tests, 0 failures, 0 errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Cache dashboard vars in the concern and invalidate from DoseLog and HealthEvent** - `1192b6f` (feat)
2. **Task 2: Tests — cache populated on first call, invalidated by DoseLog and HealthEvent writes** - `38a063b` (test)

**Plan metadata:** committed with SUMMARY.md (docs)

## Files Created/Modified
- `app/controllers/concerns/dashboard_variables.rb` - Wrapped queries in Rails.cache.fetch with 5min TTL and Date.current-keyed cache key
- `app/models/dose_log.rb` - Added after_commit invalidate_dashboard_cache on create and destroy
- `app/models/health_event.rb` - Added after_commit invalidate_dashboard_cache on create, update, and destroy
- `test/models/dose_log_test.rb` - Added DoseLogDashboardCacheTest top-level class with 2 invalidation tests
- `test/models/health_event_test.rb` - Added HealthEventDashboardCacheTest top-level class with 3 invalidation tests
- `test/controllers/dashboard_controller_test.rb` - Added DashboardVarsCacheTest with 2 integration tests

## Decisions Made
- **Top-level test class for commit callback tests**: Nested class declarations inside an existing `TestCase` class do not propagate `self.use_transactional_tests = false` correctly in the Rails 8 parallel test runner — the parent class's transaction wrapping takes precedence. Placing the cache invalidation tests as separate top-level classes (e.g. `DoseLogDashboardCacheTest`) resolves this. Matches the pattern already used in `NotificationTest::CacheInvalidationTest` in spirit but corrected for top-level placement.
- **after_commit lambda style**: RuboCop omakase auto-corrected `after_create_commit :method` to `after_commit -> { method }, on: :create`. No functional difference; accepted as correct style.
- **puffs: 99 in DoseLog cache tests**: Avoids colliding with fixture records (which use puffs: 2) when cleaning up non-transactional records in teardown via `delete_all`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Nested test class does not respect use_transactional_tests = false**
- **Found during:** Task 2 (test writing)
- **Issue:** The plan specified adding tests as nested classes inside existing test classes. In Rails 8's parallel test runner, `self.use_transactional_tests = false` on a nested class does not override the parent class's transaction wrapping — `after_commit` callbacks never fire, causing 3 test failures.
- **Fix:** Restructured cache invalidation tests as top-level classes (`DoseLogDashboardCacheTest`, `HealthEventDashboardCacheTest`) placed after the outer class's closing `end` in each test file.
- **Files modified:** test/models/dose_log_test.rb, test/models/health_event_test.rb
- **Verification:** All 7 new tests pass; full suite 515 green
- **Committed in:** `38a063b` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — Bug in test structure)
**Impact on plan:** Required restructuring nested test classes to top-level; all 7 planned tests still delivered. No scope change.

## Issues Encountered
- `after_create_commit :method` shorthand auto-corrected by RuboCop omakase to `after_commit -> { method }, on: :create` style — accepted, functionally identical.

## Next Phase Readiness
- Dashboard vars caching complete and tested; Solid Cache backed by production SQLite cache database
- Any further caching work can follow the same `Rails.cache.fetch` + `after_commit` invalidation pattern
- No blockers

---
*Phase: 22-request-path-caching*
*Completed: 2026-03-13*
