---
phase: 17-onboarding-flow
plan: 02
subsystem: onboarding
tags: [rails, views, erb, system-tests, controller-tests, capybara, selenium, fixtures]

# Dependency graph
requires:
  - phase: 17-onboarding-flow
    plan: 01
    provides: OnboardingController 2-step wizard with flag persistence, DashboardController guard, onboarding boolean flags on users table

provides:
  - Onboarding show.html.erb updated to 2-step progress indicator (aria-valuemax="2", 2 dots)
  - 13 controller tests covering all onboarding flows (dashboard redirect, flag persistence, auth guard)
  - 7 system tests covering full wizard UX, skip flows, and returning user bypass
  - new_user fixture (charlie@example.com) for testing un-onboarded user paths

affects:
  - Phase 18+ (any phase modifying the onboarding wizard needs to update these tests)
  - test/fixtures/users.yml (added new_user fixture)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "use_transactional_tests = false for system tests with multi-redirect flows — avoids shared-connection flakiness"
    - "Explicit teardown in system tests (delete_all sessions/personal_best_records, destroy_all medications) when transactional tests are disabled"
    - "update_all in setup to reset flag state between tests when transactional rollback is disabled"
    - "assert_text with wait: N after navigation actions to synchronize with Turbo-driven page transitions"

key-files:
  created:
    - test/controllers/onboarding_controller_test.rb
    - test/system/onboarding_test.rb
  modified:
    - app/views/onboarding/show.html.erb
    - test/fixtures/users.yml
    - test/fixtures/sessions.yml

key-decisions:
  - "use_transactional_tests = false for OnboardingTest: shared DB connection with lock_threads=true caused intermittent authentication failures for charlie in setup; disabling transactions with explicit teardown makes tests reliable"
  - "new_user fixture added directly with both flags=false rather than relying on default — explicit state makes test intent clear"
  - "System test setup uses User.find_by! (fresh DB query) not users(:new_user) fixture accessor — avoids cached AR instance with stale flag values"
  - "assert_text with wait:10/15 after page transitions — Turbo Drive navigations are async and the default 2s wait is insufficient under shared-connection load"
  - "No changes to _step_1.html.erb or _step_2.html.erb — both partials already had correct skip links and no step-3 references; onboarding layout already includes flash rendering"

patterns-established:
  - "System test isolation pattern: disable transactional tests + explicit teardown for tests involving multi-redirect authenticated flows"

# Metrics
duration: 45min
completed: 2026-03-10
---

# Phase 17 Plan 02: Onboarding Views and Tests Summary

**2-step progress indicator in show.html.erb (aria-valuemax="2"), plus 13 controller tests and 7 system tests covering all onboarding flows including skip paths and returning user bypass**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-03-10T16:15:00Z
- **Completed:** 2026-03-10T17:00:00Z
- **Tasks:** 2
- **Files modified/created:** 6

## Accomplishments

- Updated `show.html.erb` progress indicator from 3-step to 2-step (`aria-valuemax="2"`, `2.times` loop, aria-label updated)
- Added `new_user` fixture (charlie@example.com, both flags false) and `new_user_session` for un-onboarded user test scenarios
- 13 controller tests covering: dashboard redirect for new user, no redirect for returning user, partial completion redirect, onboarding guard, step 1/2 rendering, submit_1/submit_2 valid/invalid, skip step 1/2, auth guard
- 7 system tests covering: new user redirect on dashboard visit, full wizard completion, skip step 1 then complete step 2, complete step 1 then skip step 2, skip both steps, returning user bypass, progress indicator shows 2 steps
- All 391 tests pass (378 pre-existing + 13 new controller tests)
- System tests stable: 20/20 consecutive runs with 0 failures

## Task Commits

Each task was committed atomically:

1. **Task 1: Update onboarding views — 2-step progress indicator** - `88e6e18` (feat)
2. **Task 2: Controller tests and system tests for all onboarding flows** - `041fb23` (feat)

## Files Created/Modified

- `app/views/onboarding/show.html.erb` - Changed aria-valuemax from 3→2, aria-label "of 3"→"of 2", loops 2.times
- `test/fixtures/users.yml` - Added new_user fixture (charlie@example.com, both flags false)
- `test/fixtures/sessions.yml` - Added new_user_session fixture
- `test/controllers/onboarding_controller_test.rb` - 13 controller tests (new file)
- `test/system/onboarding_test.rb` - 7 system tests (new file)

## Decisions Made

- **use_transactional_tests = false for OnboardingTest**: Rails `lock_threads: true` shares the DB connection between test and Puma threads. Multi-redirect sign-in flows (sign-in → root_url → dashboard → onboarding) caused intermittent authentication failures when the connection was contended between Puma threads. Disabling transactional tests (with explicit setup/teardown) eliminates this race condition entirely.
- **No changes to _step_1.html.erb**: The layout already includes `render "layouts/flash"`, so inline flash rendering was not needed. The skip link (`onboarding_skip_path(1)`) was already correct.
- **No changes to _step_2.html.erb**: Already had correct back link, skip link (`onboarding_skip_path(2)`), and no step-3 references.
- **assert_text with wait:10/15**: After Turbo Drive navigations, the default Capybara wait (2s) was insufficient under shared-connection load. Explicit longer waits prevent race conditions in the test body.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] System test flakiness from shared DB connection in multi-redirect flows**
- **Found during:** Task 2 (system test implementation)
- **Issue:** With `use_transactional_tests = true` (default) and `lock_threads: true`, the test thread and Puma threads share a single pinned DB connection. When charlie's sign-in triggers a 3-redirect chain (sign-in → root_url → dashboard → onboarding), the shared connection caused intermittent authentication failures. Tests were flaky with ~30% failure rate.
- **Fix:** Set `self.use_transactional_tests = false` on OnboardingTest class with explicit setup (update_all to reset flags) and teardown (delete_all sessions/records, reset alice's flags). This gives each connection its own clean DB view.
- **Files modified:** test/system/onboarding_test.rb
- **Verification:** 20 consecutive test suite runs with 0 failures
- **Committed in:** 041fb23 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (test infrastructure bug)
**Impact on plan:** Auto-fix necessary for test reliability. No scope creep. The plan specified system tests; this deviation was the correct implementation approach for the actual Rails/Capybara environment.

## Issues Encountered

The system test flakiness took significant debugging. Root cause analysis:
1. `use_transactional_tests = true` + `lock_threads: true` → all Puma threads and the test thread share one pinned DB connection
2. Charlie's multi-redirect sign-in chain required 4 sequential Puma requests, all needing the shared connection
3. Occasional lock contention caused requests to time out, making authentication appear to fail
4. Fix: disable transactional tests + explicit teardown (standard Rails pattern for system tests with committed data requirements)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Onboarding views and tests complete; Phase 17 Plan 02 is the final plan in Phase 17
- Phase 17 is COMPLETE: data layer (17-01) + views + tests (17-02) both done
- New user fixture (`charlie@example.com`) available for any future tests that need an un-onboarded user
- System test isolation pattern documented — use for any future tests with multi-redirect authenticated flows

## Self-Check: PASSED

- `app/views/onboarding/show.html.erb`: FOUND (aria-valuemax="2" at line 13)
- `test/controllers/onboarding_controller_test.rb`: FOUND (13 tests)
- `test/system/onboarding_test.rb`: FOUND (7 tests)
- `test/fixtures/users.yml`: FOUND (new_user fixture with both flags false)
- `test/fixtures/sessions.yml`: FOUND (new_user_session fixture)
- commit 88e6e18: FOUND (feat: update onboarding progress indicator to 2-step)
- commit 041fb23: FOUND (feat: add controller and system tests for all onboarding flows)
- All 391 controller tests pass (bin/rails test)
- All 7 system tests pass (bin/rails test test/system/onboarding_test.rb, 20/20 consecutive runs)

---
*Phase: 17-onboarding-flow*
*Completed: 2026-03-10*
