---
phase: 14-adherence-dashboard
plan: 01
subsystem: testing
tags: [rails, service-object, adherence, dose-tracking, minitest, tdd]

requires:
  - phase: 10-medication-model
    provides: Medication model with doses_per_day column
  - phase: 12-dose-logging
    provides: DoseLog model with recorded_at and medication association

provides:
  - AdherenceCalculator service object at app/services/adherence_calculator.rb
  - AdherenceCalculator.call(medication, date) returning Result with taken/scheduled/status
  - Unit test coverage for all status branches (:on_track, :missed, :no_schedule)

affects:
  - 14-02-adherence-dashboard-partial
  - 14-03-adherence-history-controller

tech-stack:
  added: []
  patterns:
    - "Service object pattern: AdherenceCalculator.call(args) delegates to new(args).call"
    - "Struct result: Result = Struct.new(:taken, :scheduled, :status) for value objects"
    - "Pre-creation date guard: early return with taken:0, scheduled:nil when date < created_at.to_date"

key-files:
  created:
    - app/services/adherence_calculator.rb
    - test/services/adherence_calculator_test.rb
  modified: []

key-decisions:
  - "Pre-creation date returns taken:0 not actual log count — medication did not exist that day so logs are semantically invalid"
  - "Pre-creation check uses early return before querying dose_logs — prevents counting logs that predated the medication"
  - "status :no_schedule emitted for both nil doses_per_day and pre-creation dates — both mean adherence is unmeasurable"

patterns-established:
  - "AdherenceCalculator.call(medication, date) is the single external entry point for adherence logic"
  - "Result Struct used rather than OpenStruct or Hash — typed, immutable value object"

requirements_covered: []

duration: 5min
completed: 2026-03-08
---

# Phase 14 Plan 01: AdherenceCalculator Service Object Summary

**AdherenceCalculator service object returning a typed Result struct with taken/scheduled/status — core domain logic for the adherence dashboard, fully unit-tested across all status branches.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-08T00:00:00Z
- **Completed:** 2026-03-08T00:05:00Z
- **Tasks:** 2 (TDD RED + GREEN)
- **Files modified:** 2

## Accomplishments

- Service object `AdherenceCalculator.call(medication, date)` with clean single entry point
- Returns `Result` struct with `taken` (count of dose log records), `scheduled` (doses_per_day), `status` (:on_track/:missed/:no_schedule)
- 7 unit tests covering: on_track, missed-partial, missed-none, no_schedule (nil doses), pre-creation date, and boundary conditions
- Full test suite: 283 tests passing, 0 failures, 0 regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: RED — Write failing tests for AdherenceCalculator** - `6f1c774` (test)
2. **Task 2: GREEN — Implement AdherenceCalculator to pass tests** - `7344a56` (feat)

_Note: TDD tasks have test commit then implementation commit_

## Files Created/Modified

- `app/services/adherence_calculator.rb` - Service object with call/initialize/call methods and Result struct
- `test/services/adherence_calculator_test.rb` - 7 unit tests covering all status branches

## Decisions Made

- **Pre-creation date guard uses early return**: When `date < medication.created_at.to_date`, returns `Result.new(0, nil, :no_schedule)` immediately without querying dose_logs. This prevents counting dose logs that existed before the medication was formally added — semantically those logs cannot exist.
- **status :no_schedule for both cases**: `nil doses_per_day` (unscheduled medication like a reliever) and pre-creation date both yield `:no_schedule`. Both represent "adherence unmeasurable" from a clinical perspective.
- **taken reflects count of log records, not sum of puffs**: Each DoseLog record = one administration event. count of records = "doses taken today" for adherence purposes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Pre-creation date guard must return taken:0, not actual log count**
- **Found during:** Task 2 (GREEN implementation)
- **Issue:** Plan skeleton computed `taken` before the status guard, so pre-creation branch still returned actual log count (fixture `alice_preventer_dose_1` is 1.day.ago; fixture medication created_at is today, so past_date = yesterday, which found that log)
- **Fix:** Added early return before the dose_logs query when `date < medication.created_at.to_date`, returning `Result.new(0, nil, :no_schedule)`
- **Files modified:** app/services/adherence_calculator.rb
- **Verification:** `test_returns_no_schedule_for_a_date_before_the_medication_was_created` passes; all 7 tests pass; 283-test suite green
- **Committed in:** `7344a56` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug in plan skeleton)
**Impact on plan:** Fix necessary for spec correctness. The plan's skeleton computed taken before the guard — early return resolves it cleanly. No scope creep.

## Issues Encountered

None beyond the auto-fixed bug above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `AdherenceCalculator.call(medication, date)` is ready for use by Plan 14-02 (dashboard partial) and Plan 14-03 (history controller)
- Service follows standard Rails autoload path (app/services/) — no require needed in consuming code
- No blockers

---
*Phase: 14-adherence-dashboard*
*Completed: 2026-03-08*

## Self-Check: PASSED

- app/services/adherence_calculator.rb: FOUND
- test/services/adherence_calculator_test.rb: FOUND
- 14-01-SUMMARY.md: FOUND
- commit 6f1c774 (test - RED): FOUND
- commit 7344a56 (feat - GREEN): FOUND
