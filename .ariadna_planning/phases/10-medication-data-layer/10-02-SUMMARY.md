---
phase: 10-medication-data-layer
plan: 02
subsystem: database

tags: [rails, activerecord, sqlite, migration, dose-logging, associations]

# Dependency graph
requires:
  - phase: 10-01
    provides: Medication model with belongs_to :user, medications table and fixtures
  - phase: 02-authentication
    provides: User model used as FK target

provides:
  - dose_logs table with user_id, medication_id, puffs, recorded_at, indexes on recorded_at and [medication_id, recorded_at]
  - DoseLog ActiveRecord model with belongs_to :user, belongs_to :medication, puffs/recorded_at validations
  - chronological and for_medication scopes on DoseLog
  - has_many :dose_logs on both Medication and User (dependent: :destroy)
  - dose_logs.yml fixtures for alice and bob
  - DoseLogTest covering all plan truths (15 tests passing)

affects:
  - 10-03 (remaining-dose calculation reads DoseLog puffs per medication)
  - phase-13 (low-stock warnings query dose_logs via [medication_id, recorded_at] compound index)
  - phase-14 (adherence tracking reads DoseLog per day)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "DoseLog belongs_to :user and belongs_to :medication (both required, no optional: true)"
    - "Compound index [:medication_id, :recorded_at] supports remaining-dose sum query pattern"
    - "Cascade deletion via dependent: :destroy on both Medication and User associations"
    - "Cascade test uses DoseLog.exists? instead of assert_difference to avoid counting fixture records"

key-files:
  created:
    - db/migrate/20260308162658_create_dose_logs.rb
    - app/models/dose_log.rb
    - test/fixtures/dose_logs.yml
    - test/models/dose_log_test.rb
  modified:
    - app/models/medication.rb
    - app/models/user.rb
    - db/schema.rb

key-decisions:
  - "puffs validated as integer > 0 — zero or negative puffs would corrupt remaining-dose calculations downstream"
  - "compound index on [medication_id, recorded_at] added at creation time to support the Plan 10-03 sum query pattern"
  - "dependent: :destroy on both User and Medication ensures no orphaned dose logs — cross-association cleanup enforced at model layer"

# Metrics
duration: 2min
completed: 2026-03-08
---

# Phase 10 Plan 02: DoseLog Model Summary

**dose_logs table, DoseLog ActiveRecord model with presence/numericality validations, belongs_to associations on both User and Medication, compound index on [medication_id, recorded_at] for downstream sum queries, and 15 passing model tests.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-08T16:26:53Z
- **Completed:** 2026-03-08T16:28:19Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- dose_logs migration created with user_id, medication_id (foreign keys), puffs (integer not null), recorded_at, plus single-column index on recorded_at and compound index on [medication_id, recorded_at]
- DoseLog model with belongs_to :user and belongs_to :medication, puffs validates as integer > 0, recorded_at validates presence, chronological and for_medication scopes
- has_many :dose_logs, dependent: :destroy added to both Medication and User models
- Four fixtures covering alice reliever (x2), alice preventer (x1), bob reliever (x1) for cross-user isolation
- 15 model tests pass covering all plan truths: persistence, all four validation failure modes, all association directions, both scopes, and cascade deletion

## Task Commits

Each task was committed atomically:

1. **Task 1: Create dose_logs migration and DoseLog model** - `d4abf24` (feat)
2. **Task 2: Add fixtures and model tests for DoseLog** - `ffb7aeb` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `db/migrate/20260308162658_create_dose_logs.rb` - CreateDoseLogs migration with all columns, FK constraints, and both indexes
- `app/models/dose_log.rb` - DoseLog model with belongs_to, validations, two scopes
- `app/models/medication.rb` - Added has_many :dose_logs, dependent: :destroy
- `app/models/user.rb` - Added has_many :dose_logs, dependent: :destroy
- `db/schema.rb` - Updated with dose_logs table definition
- `test/fixtures/dose_logs.yml` - Four fixtures for alice and bob
- `test/models/dose_log_test.rb` - 15 tests covering all plan truths

## Decisions Made

- `puffs` validated as integer > 0 — zero or negative values would silently corrupt remaining-dose calculations in Plan 10-03
- Compound index `[:medication_id, :recorded_at]` added at table creation, not deferred — it directly supports the sum query that Plan 10-03 will use
- `dependent: :destroy` on both `Medication` and `User` associations — dose logs are meaningless without either parent and must be cleaned up on either cascade path

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed cascade deletion test counting fixture records**
- **Found during:** Task 2 (running tests)
- **Issue:** Plan's test used `assert_difference "DoseLog.count", -1` but alice_reliever fixture already has 2 dose logs — destroying @medication removes all 3 (2 fixtures + 1 created), not -1
- **Fix:** Replaced `assert_difference` with `assert_not DoseLog.exists?(log.id)` — verifies the specific record is gone without depending on total count
- **Files modified:** test/models/dose_log_test.rb
- **Verification:** 15 tests, 0 failures after fix
- **Committed in:** ffb7aeb (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug in test assertion, same pattern as 10-01)
**Impact on plan:** Fix was necessary for test correctness. No change to model behaviour, validations, or associations.

## Issues Encountered

None beyond the auto-fixed test assertion bug.

## User Setup Required

None — no external services or environment variables required.

## Next Phase Readiness

- dose_logs table and DoseLog model are complete — ready for Plan 10-03 (remaining-dose calculation)
- Compound index on [medication_id, recorded_at] is in place for the sum query Plan 10-03 will add
- Cascade deletion confirmed working on both Medication and User paths

---
*Phase: 10-medication-data-layer*
*Completed: 2026-03-08*

## Self-Check: PASSED

- FOUND: db/migrate/20260308162658_create_dose_logs.rb
- FOUND: app/models/dose_log.rb
- FOUND: test/fixtures/dose_logs.yml
- FOUND: test/models/dose_log_test.rb
- FOUND: .ariadna_planning/phases/10-medication-data-layer/10-02-SUMMARY.md
- FOUND commit: d4abf24 (Task 1)
- FOUND commit: ffb7aeb (Task 2)
