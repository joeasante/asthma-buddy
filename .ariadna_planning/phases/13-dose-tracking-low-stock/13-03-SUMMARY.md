---
phase: 13-dose-tracking-low-stock
plan: 03
subsystem: testing

tags: [rails, minitest, capybara, selenium, system-tests, low-stock, refill, turbo-stream]

# Dependency graph
requires:
  - phase: 13-01
    provides: "Medication#low_stock?, Medication#days_of_supply_remaining, dashboard @low_stock_medications"
  - phase: 13-02
    provides: "Settings::MedicationsController#refill, refill_settings_medication_path, inline refill form on medication card"

provides:
  - "5 model unit tests for Medication#low_stock? (boundary cases, nil schedule, after logging)"
  - "4 controller integration tests for Settings::MedicationsController#refill (success, count=0, cross-user 404, unauthenticated redirect)"
  - "6 system tests for low-stock warning display, dashboard section, and refill clearing the badge"

affects: [future phase regression prevention, TRACK-01, TRACK-02, TRACK-03]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "System tests create low-stock fixtures inline with Medication.create! rather than relying on fixture data"
    - "Medication card system tests scope with within '.medication-card', text: 'Name' for named card isolation"
    - "Refill controller tests use sign_out before the unauthenticated test since setup signs in via SessionTestHelper"

key-files:
  created:
    - test/system/low_stock_test.rb
  modified:
    - test/models/medication_test.rb
    - test/controllers/settings/medications_controller_test.rb

key-decisions:
  - "System tests create low-stock medication inline in setup rather than adding fixture — 20 doses / 2 per day = 10 days below 14-day threshold"
  - "Refill unauthenticated test calls sign_out first since controller test setup signs in as @user via SessionTestHelper"
  - "Route verified as refill_settings_medication_path (not refill_settings_medication_path) via bin/rails routes"

patterns-established:
  - "System test medication card scoping: within '.medication-card', text: 'MedName' for named card isolation"
  - "Inline refill system test: find('details.refill-details summary').click to open, fill_in 'medication[starting_dose_count]' to set count"

requirements_covered:
  - id: "TRACK-01"
    description: "low_stock? predicate tested at boundary (14.0 = false, <14 = true), nil schedule, after logging"
    evidence: "test/models/medication_test.rb (5 new low_stock? tests)"
  - id: "TRACK-02"
    description: "Refill action tested: success with Turbo Stream media type, starting_dose_count updated, refilled_at set, cross-user 404, unauthenticated redirect"
    evidence: "test/controllers/settings/medications_controller_test.rb (4 new refill tests)"
  - id: "TRACK-03"
    description: "System tests confirm low-stock badge on card and dashboard section when supply < 14 days; badge and section disappear after sufficient refill"
    evidence: "test/system/low_stock_test.rb (6 system tests)"

# Metrics
duration: 8min
completed: 2026-03-08
---

# Phase 13 Plan 03: Phase 13 Test Coverage Summary

**Regression-locking tests for low_stock? predicate (5 model), refill controller action (4 integration), and low-stock badge/dashboard UI flows (6 system) — 276 tests total, no regressions**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-08T00:00:00Z
- **Completed:** 2026-03-08T00:08:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- 5 model unit tests lock in Medication#low_stock? boundary behaviour (14.0 = false, 13.0 = true), nil schedule guard, zero starting count, and after-logging threshold drop
- 4 controller integration tests verify the refill action: Turbo Stream media type, starting_dose_count update, refilled_at set, cross-user 404 isolation, and unauthenticated redirect
- 6 system tests with Capybara/Selenium confirm: low-stock badge on medication card, no badge without doses_per_day, dashboard Medications section visible/hidden, badge cleared after UI refill, dashboard hidden after model refill

## Requirements Covered

| REQ-ID | Requirement | Evidence |
|--------|-------------|----------|
| TRACK-01 | low_stock? tested at boundary, nil schedule, after logging | test/models/medication_test.rb |
| TRACK-02 | Refill action: Turbo Stream, count update, refilled_at, 404, redirect | test/controllers/settings/medications_controller_test.rb |
| TRACK-03 | System tests: badge on card, dashboard section, refill clears badge | test/system/low_stock_test.rb |

## Task Commits

Each task was committed atomically:

1. **Task 1: Model unit tests for low_stock? and controller tests for refill action** - `0e753c4` (test)
2. **Task 2: System tests for low-stock warning display and refill clearing the badge** - `0016a77` (test)

**Plan metadata:** `[docs commit hash]` (docs: complete plan)

## Files Created/Modified

- `test/models/medication_test.rb` - Added 5 new low_stock? tests in a dedicated section at the end
- `test/controllers/settings/medications_controller_test.rb` - Added 4 new refill action tests in a dedicated section at the end
- `test/system/low_stock_test.rb` - New system test file with 6 tests covering badge display, dashboard section, and refill clearing badge

## Decisions Made

- System tests create the low-stock medication inline in setup (`Medication.create!` with `starting_dose_count: 20, doses_per_day: 2` = 10 days) rather than modifying fixtures — fixtures would affect other tests relying on alice_preventer's 59-day supply
- The unauthenticated refill controller test calls `sign_out` first because the controller test setup signs in as `@user` via `SessionTestHelper`
- Route confirmed as `refill_settings_medication_path` via `bin/rails routes | grep refill` (plan noted to verify this)
- System test scopes to medication card with `within ".medication-card", text: "TestPreventer"` — sufficient for isolation since the medication name is unique in the test session

## Deviations from Plan

None - plan executed exactly as written. The route name (`refill_settings_medication_path`) was verified as directed by the plan note, and matched.

## Issues Encountered

None — `bin/rails test:system test/system/low_stock_test.rb` ran all system tests (including pre-existing failures in other test files unrelated to this plan). Running `bin/rails test test/system/low_stock_test.rb` ran only the new file — all 6 tests passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 13 is now fully complete: feature implementation (Plans 01-02) and test coverage (Plan 03) are both done
- 276 tests passing with no regressions — safe baseline for next milestone phase
- Low-stock warning, refill action, and dashboard section are regression-locked

---
*Phase: 13-dose-tracking-low-stock*
*Completed: 2026-03-08*
