---
phase: 17-onboarding-flow
plan: gap-01
subsystem: ui
tags: [rails, onboarding, controller, flash, redirect]

# Dependency graph
requires:
  - phase: 17-onboarding-flow
    provides: OnboardingController with 2-step wizard, DashboardController#check_onboarding guard, onboarding_complete? method
provides:
  - Fixed skip action for step 2 — both onboarding flags set atomically, flash notice survives dashboard redirect
  - Two controller tests covering flash notice survival after skipping both steps
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Both-flags-true pattern: skipping any final onboarding step must set ALL remaining flags to make onboarding_complete? return true definitively"

key-files:
  created: []
  modified:
    - app/controllers/onboarding_controller.rb
    - test/controllers/onboarding_controller_test.rb

key-decisions:
  - "Skip step 2 must set onboarding_personal_best_done: true alongside onboarding_medication_done: true — skipping the final step is an implicit skip of all pending steps"
  - "follow_redirect! then flash[:notice] is the correct assertion pattern for ActionDispatch::IntegrationTest flash after redirect"

patterns-established:
  - "Onboarding skip-final-step pattern: always set ALL flags to true, not just the current step's flag"

requirements_covered: []

# Metrics
duration: 5min
completed: 2026-03-10
---

# Phase 17 Gap-01: Onboarding Skip Flash Notice Fix Summary

**One-line fix to OnboardingController#skip step 2 — sets both onboarding flags atomically so `onboarding_complete?` returns true, preventing DashboardController from firing a second redirect that discards the flash notice.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-10T00:00:00Z
- **Completed:** 2026-03-10T00:05:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Fixed `OnboardingController#skip` `when 2` branch to call `update!(onboarding_personal_best_done: true, onboarding_medication_done: true)` — one attribute addition
- After fix, `onboarding_complete?` returns true after skipping step 2 regardless of whether step 1 was completed or skipped
- Flash notice "You can complete setup any time from Settings." now survives the dashboard redirect because `check_onboarding` is a no-op when both flags are true
- Added two targeted controller tests: one for skip-step-2-after-step-1-done, one for skip-both-steps — both assert `flash[:notice]` after `follow_redirect!`

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix OnboardingController#skip step 2 to set both onboarding flags** - `443b17a` (fix)
2. **Task 2: Add controller tests for skip-step-2 flash notice and skip-both-steps path** - `9b12ce0` (test)

## Files Created/Modified
- `app/controllers/onboarding_controller.rb` - `when 2` branch now sets both `onboarding_personal_best_done: true` and `onboarding_medication_done: true`; JSON response includes both flags
- `test/controllers/onboarding_controller_test.rb` - Replaced single skip-step-2 test with two tests: (a) skip after step 1 done with flash assertion, (b) skip both steps with both-flags-true and flash assertion

## Decisions Made
- Skip step 2 sets `onboarding_personal_best_done: true` alongside `onboarding_medication_done: true` — skipping the final step is an implicit acknowledgement that all remaining steps are being skipped, so all flags must be set to definitively close onboarding
- `follow_redirect!` then `flash[:notice]` is the correct pattern for `ActionDispatch::IntegrationTest` — flash is unconsumed until the next request

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- UAT gap closed: skip-both-steps flash notice now survives. Phase 17 UAT item can be marked passed.
- No blockers.

## Self-Check

Files exist:
- `app/controllers/onboarding_controller.rb` — modified
- `test/controllers/onboarding_controller_test.rb` — modified

Commits exist:
- `443b17a` — fix(17-gap-01): set both onboarding flags when skipping step 2
- `9b12ce0` — test(17-gap-01): add two skip-step-2 tests covering flash notice survival

Test counts: 14 onboarding controller tests passing, 396 total tests passing (0 failures, 0 errors, 0 skips).

## Self-Check: PASSED

---
*Phase: 17-onboarding-flow*
*Completed: 2026-03-10*
