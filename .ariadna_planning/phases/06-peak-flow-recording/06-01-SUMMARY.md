---
phase: 06-peak-flow-recording
plan: 01
subsystem: database
tags: [rails, activerecord, sqlite, models, validations, enums, zones]

# Dependency graph
requires:
  - phase: 03-symptom-recording
    provides: SymptomLog model pattern (enum, validations, composite index, belongs_to :user)
  - phase: 02-authentication
    provides: User model with has_secure_password
provides:
  - PeakFlowReading model with zone enum (green/yellow/red), validations, before_save zone assignment
  - PersonalBestRecord model with 100-900 L/min validation range and current_for scope
  - User has_many :peak_flow_readings and :personal_best_records with dependent: :destroy
  - Fixtures for both models
  - Model tests: 22 tests covering zone calculation, validations, current_for
affects:
  - 06-02 (controller/views depend on these models)
  - 06-03+ (all subsequent Phase 6 plans)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Zone calculation using personal best at reading time (not current personal best)
    - enum with allow_nil: true for nullable zone field
    - before_save callback for derived field assignment
    - Composite index [user_id, recorded_at] for timeline queries

key-files:
  created:
    - app/models/peak_flow_reading.rb
    - app/models/personal_best_record.rb
    - db/migrate/20260307162243_create_peak_flow_readings.rb
    - db/migrate/20260307162318_create_personal_best_records.rb
    - test/fixtures/peak_flow_readings.yml
    - test/fixtures/personal_best_records.yml
    - test/models/peak_flow_reading_test.rb
    - test/models/personal_best_record_test.rb
  modified:
    - app/models/user.rb

key-decisions:
  - "Zone calculation uses personal best at reading time (via recorded_at <= self.recorded_at query), not current personal best — ensures historical accuracy"
  - "zone column is nullable integer; zone enum uses validate: { allow_nil: true } — nil zone when no personal best exists is a valid state"
  - "PersonalBestRecord validation range 100-900 L/min — covers physiologically plausible peak flow values"
  - "before_save :assign_zone callback on PeakFlowReading — zone is always derived, never manually set by callers"

patterns-established:
  - "personal_best_at_reading_time: query personal_best_records with recorded_at <= self.recorded_at, order desc, pick(:value)"
  - "compute_zone: green >= 80%, yellow 50-79%, red < 50% of personal best"
  - "current_for(user): user.personal_best_records.chronological.first"

# Metrics
duration: 8min
completed: 2026-03-07
---

# Phase 6 Plan 01: Peak Flow Core Models Summary

**PeakFlowReading and PersonalBestRecord ActiveRecord models with zone calculation (green/yellow/red at 80%/50% thresholds), nullable zone enum, composite indexes, and 22 model tests.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-07T16:22:27Z
- **Completed:** 2026-03-07T16:30:00Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- PeakFlowReading model: integer value, datetime recorded_at, nullable zone enum (green=0/yellow=1/red=2), belongs_to :user, before_save assigns zone from personal best history
- PersonalBestRecord model: integer value validated 100-900 L/min, chronological scope, current_for(user) class method
- User model updated with has_many :peak_flow_readings and :personal_best_records, both with dependent: :destroy
- Fixtures for both tables (4 peak_flow_readings, 3 personal_best_records using verified_user/unverified_user)
- 22 model tests covering all zone thresholds, nil zone when no personal best, validation boundaries, current_for lookup

## Task Commits

Each task was committed atomically:

1. **Task 1: PeakFlowReading migration and model with zone calculation** - `6bb9df2` (feat)
2. **Task 2: PersonalBestRecord migration, model, User associations, fixtures, and model tests** - `21ed1f9` (feat)

## Files Created/Modified

- `app/models/peak_flow_reading.rb` - Zone enum, validations, chronological scope, compute_zone, before_save callback
- `app/models/personal_best_record.rb` - Validations (100-900 range), chronological scope, current_for class method
- `app/models/user.rb` - Added has_many :peak_flow_readings and :personal_best_records
- `db/migrate/20260307162243_create_peak_flow_readings.rb` - peak_flow_readings table with composite index
- `db/migrate/20260307162318_create_personal_best_records.rb` - personal_best_records table with composite index
- `test/fixtures/peak_flow_readings.yml` - 4 fixtures covering green/yellow/nil zone and cross-user
- `test/fixtures/personal_best_records.yml` - 3 fixtures (alice with 2 records at different times, bob with 1)
- `test/models/peak_flow_reading_test.rb` - 11 tests: zone calculation, validations, chronological scope
- `test/models/personal_best_record_test.rb` - 11 tests: value boundary validations, current_for

## Decisions Made

- Zone calculation uses personal best at reading time (recorded_at <= self.recorded_at), not current personal best — ensures historical readings show accurate zones for the period they were recorded.
- zone column is nullable (no integer constraint at DB level); enum uses `validate: { allow_nil: true }` — nil zone is a legitimate state when no personal best record precedes the reading.
- PersonalBestRecord value range 100-900 L/min covers the physiologically plausible range for adult peak flow.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed test values for compute_zone green/yellow tests**
- **Found during:** Task 2 (model tests)
- **Issue:** Test used personal_best = 500 at `1.day.ago`, but alice_updated_personal_best fixture (value 520) is the actual personal best at that time — so threshold values 400 and 250 produced wrong zones.
- **Fix:** Updated test values to match actual personal best of 520 at `1.day.ago` — green test uses 420 (>= 80% of 520), yellow test uses 280 (50-79% of 520).
- **Files modified:** `test/models/peak_flow_reading_test.rb`
- **Verification:** All 22 tests pass after fix
- **Committed in:** `21ed1f9` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug in test fixture assumptions)
**Impact on plan:** Auto-fix necessary for test correctness. No scope creep.

## Issues Encountered

None beyond the test fixture mismatch documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Both models migrated and tested — Phase 6 plans 02+ (controller, views, system tests) can proceed.
- Fixtures available for controller/integration tests.
- No blockers.

---
*Phase: 06-peak-flow-recording*
*Completed: 2026-03-07*
