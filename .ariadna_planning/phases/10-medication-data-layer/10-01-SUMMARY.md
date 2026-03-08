---
phase: 10-medication-data-layer
plan: 01
subsystem: database
tags: [rails, activerecord, sqlite, enum, migration, medication]

# Dependency graph
requires:
  - phase: 02-authentication
    provides: User model with has_secure_password and sessions
  - phase: 06-peak-flow-recording
    provides: Pattern for integer enum columns, fixture conventions, model test conventions

provides:
  - medications table with 8 columns and enum index
  - Medication ActiveRecord model with four-value enum (reliever/preventer/combination/other)
  - Model validations for required and optional numeric fields
  - belongs_to :user association (and has_many :medications on User)
  - chronological scope
  - medications.yml fixtures for alice and bob
  - MedicationTest covering all truths from the plan

affects:
  - 10-02 (dose logging writes to medications)
  - 10-03 (tracking reads medication.starting_dose_count)
  - 10-04 (adherence reads medication.medication_type to identify preventers)
  - 11-onboarding (checks for presence of medications)
  - any phase querying medications for a user

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "enum :field, hash, validate: true (Rails 7+ keyword syntax with validation)"
    - "Integer enum stored in DB; fixture values written as raw integers (bypass accessor)"
    - "optional numeric columns use allow_nil: true on numericality validator"
    - "Scope :chronological orders by created_at: :desc for display"

key-files:
  created:
    - db/migrate/20260308162300_create_medications.rb
    - app/models/medication.rb
    - test/fixtures/medications.yml
    - test/models/medication_test.rb
  modified:
    - app/models/user.rb
    - db/schema.rb

key-decisions:
  - "medication_type stored as integer enum (0=reliever, 1=preventer, 2=combination, 3=other) with validate: true to produce validation errors on unknown values rather than ArgumentError"
  - "starting_dose_count allows zero (greater_than_or_equal_to: 0) — an empty inhaler is a valid starting state"
  - "sick_day_dose_puffs and doses_per_day are nullable integer columns with allow_nil: true so they validate only when present"

patterns-established:
  - "Medication enum: use enum :field, hash, validate: true (not enum field: hash)"
  - "Fixture enum values: write integer directly (0, 1, 2, 3) since Rails fixtures bypass enum accessors"
  - "Chronological scope test: scope user-scoped comparison query to same user, not Medication.all"

# Metrics
duration: 6min
completed: 2026-03-08
---

# Phase 10 Plan 01: Medication Data Layer Summary

**SQLite medications table and Medication ActiveRecord model with four-value enum, field-level validations, and 19 passing model tests — foundational data store for all Milestone 2 medication management.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-08T16:22:55Z
- **Completed:** 2026-03-08T16:29:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Medications table created with all required columns, foreign key, and enum index
- Medication model with Rails 7+ enum syntax, presence/numericality validations for all fields, and chronological scope
- 19 model tests pass covering persistence, all four enum values, required/optional field validation, user association, and scope

## Task Commits

Each task was committed atomically:

1. **Task 1: Create medications migration and Medication model** - `1692da4` (feat)
2. **Task 2: Add fixtures and model tests for Medication** - `faa914d` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `db/migrate/20260308162300_create_medications.rb` - CreateMedications migration with all columns and enum index
- `app/models/medication.rb` - Medication model with enum, validations, scope, belongs_to
- `app/models/user.rb` - Added has_many :medications, dependent: :destroy
- `db/schema.rb` - Updated with medications table definition
- `test/fixtures/medications.yml` - Four fixtures: alice_reliever, alice_preventer, alice_combination, bob_reliever
- `test/models/medication_test.rb` - 19 tests covering all plan truths

## Decisions Made

- `medication_type` uses integer enum with `validate: true` — unknown values produce validation errors rather than ArgumentError, which is safer in form submission context
- `starting_dose_count` accepts zero (`greater_than_or_equal_to: 0`) — a fully used inhaler is a valid starting point for tracking
- `sick_day_dose_puffs` and `doses_per_day` are nullable columns validated only when present (`allow_nil: true`)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed chronological scope test comparing mismatched scopes**
- **Found during:** Task 2 (add fixtures and model tests)
- **Issue:** Plan's test used `Medication.order(created_at: :desc).to_a` (all users) vs `@user.medications.chronological.to_a` (single user) — these never match when multiple users have medications
- **Fix:** Changed expected to `@user.medications.order(created_at: :desc).to_a` so both sides use the same user scope
- **Files modified:** test/models/medication_test.rb
- **Verification:** 19 tests, 0 failures after fix
- **Committed in:** faa914d (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug in test assertion)
**Impact on plan:** Fix was necessary for test correctness. No scope change to the model or scope definition.

## Issues Encountered

None beyond the auto-fixed test assertion bug.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Medications table and model are complete — ready for dose logging (Phase 10-02)
- User model correctly destroys medications on account deletion (cascade in place)
- All four enum values confirmed working; fixtures available for downstream controller and integration tests

---
*Phase: 10-medication-data-layer*
*Completed: 2026-03-08*

## Self-Check: PASSED

- FOUND: db/migrate/20260308162300_create_medications.rb
- FOUND: app/models/medication.rb
- FOUND: test/fixtures/medications.yml
- FOUND: test/models/medication_test.rb
- FOUND: .ariadna_planning/phases/10-medication-data-layer/10-01-SUMMARY.md
- FOUND commit: 1692da4 (Task 1)
- FOUND commit: faa914d (Task 2)
