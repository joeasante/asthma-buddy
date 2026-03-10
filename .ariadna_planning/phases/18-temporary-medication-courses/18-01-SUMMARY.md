---
phase: 18-temporary-medication-courses
plan: 01
subsystem: database
tags: [rails, activerecord, sqlite, migration, scopes, validations, adherence]

# Dependency graph
requires:
  - phase: 10-medication-management
    provides: Medication model, medication_type enum, low_stock?, days_of_supply_remaining
  - phase: 14-adherence-tracking
    provides: AdherenceCalculator, DashboardController preventer adherence, AdherenceController history
provides:
  - course boolean column (NOT NULL DEFAULT false) on medications table
  - starts_on and ends_on date columns on medications table
  - index on medications.ends_on
  - active_courses scope (course: true, ends_on >= today)
  - archived_courses scope (course: true, ends_on < today)
  - non_courses scope (course: false)
  - course_active? instance predicate
  - Course validations (starts_on/ends_on presence, ends_on > starts_on when course: true)
  - Updated low_stock? — returns false for active courses
  - DashboardController @preventer_adherence and @low_stock_medications exclude course medications
  - AdherenceController preventers query excludes course medications
affects:
  - 18-02-ui (depends on these scopes and column names being stable)
  - DashboardController (preventer adherence now excludes courses)
  - AdherenceController (history now excludes courses)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Scope-based auto-archive: no background job, no archived boolean — time comparison in SQL"
    - "Course exclusion at query level: .where(course: false) in controller queries"
    - "Conditional validations with_options if: :course? pattern"

key-files:
  created:
    - db/migrate/20260310191313_add_course_fields_to_medications.rb
  modified:
    - app/models/medication.rb
    - app/controllers/dashboard_controller.rb
    - app/controllers/adherence_controller.rb
    - test/models/medication_test.rb
    - test/fixtures/medications.yml

key-decisions:
  - "active_courses scope uses ends_on >= Date.today (SQL) — no archived boolean column needed"
  - "course exclusion at query level with .where(course: false) — not just relying on low_stock? return false"
  - "with_options if: :course? for conditional validations — only course medications require dates"
  - "ends_on must be strictly after starts_on — equals is rejected as a zero-duration course is meaningless"
  - "low_stock? returns false for course_active? — active courses are short-lived, stock alerts not useful"
  - "index on ends_on added per user decision — scope queries filter by ends_on frequently"

patterns-established:
  - "Course scope pattern: .where(course: true).where('ends_on >= ?', Date.today)"
  - "Controller exclusion pattern: chain .where(course: false) before adherence/low-stock queries"

requirements_covered:
  - id: "COURSE-01"
    description: "course, starts_on, ends_on columns on medications table"
    evidence: "db/migrate/20260310191313_add_course_fields_to_medications.rb"
  - id: "COURSE-02"
    description: "active_courses and archived_courses scopes"
    evidence: "app/models/medication.rb scope definitions"
  - id: "COURSE-03"
    description: "Active courses excluded from adherence and low-stock"
    evidence: "DashboardController .where(course: false), AdherenceController .where(course: false), low_stock? course_active? guard"

# Metrics
duration: 3min
completed: 2026-03-10
---

# Phase 18 Plan 01: Temporary Medication Courses — Data Layer Summary

**Scope-based course auto-archive with SQL time comparison: course/starts_on/ends_on columns, active_courses/archived_courses/non_courses scopes, course validations, and query-level exclusion from preventer adherence and low-stock alerts in DashboardController and AdherenceController.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-10T19:13:08Z
- **Completed:** 2026-03-10T19:15:51Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Migration adds `course` (boolean, NOT NULL DEFAULT false), `starts_on` (date), `ends_on` (date), and index on `ends_on` to the medications table
- Medication model: `active_courses`, `archived_courses`, `non_courses` scopes; `course_active?` predicate; conditional validations with `with_options if: :course?`; `low_stock?` returns false for `course_active?` medications
- DashboardController `@preventer_adherence` and `@low_stock_medications` both chain `.where(course: false)`
- AdherenceController `preventers` query chains `.where(course: false)`
- 14 new model tests covering all scopes, validations, `course_active?`, and `low_stock?` course exclusion
- 410 total tests passing, 0 failures, 0 regressions (was 396)

## Requirements Covered

| REQ-ID | Requirement | Evidence |
|--------|-------------|----------|
| COURSE-01 | course/starts_on/ends_on columns on medications table | `db/migrate/20260310191313_add_course_fields_to_medications.rb` |
| COURSE-02 | active_courses and archived_courses scopes | `app/models/medication.rb` scope definitions |
| COURSE-03 | Active courses excluded from adherence and low-stock | `DashboardController`, `AdherenceController`, `low_stock?` guard |

## Task Commits

Each task was committed atomically:

1. **Task 1: Migration and Medication model** - `489801e` (feat)
2. **Task 2: Controller exclusions, fixtures, and model tests** - `c5d890b` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `db/migrate/20260310191313_add_course_fields_to_medications.rb` - Adds course boolean, starts_on date, ends_on date, index on ends_on
- `db/schema.rb` - Updated to reflect new columns and index
- `app/models/medication.rb` - active_courses/archived_courses/non_courses scopes, course_active? predicate, course validations, updated low_stock?
- `app/controllers/dashboard_controller.rb` - @preventer_adherence and @low_stock_medications query both exclude course medications
- `app/controllers/adherence_controller.rb` - preventers query excludes course medications
- `test/models/medication_test.rb` - 14 new tests for scopes, validations, course_active?, low_stock? course exclusion
- `test/fixtures/medications.yml` - alice_active_course (ends_on +7 days) and alice_archived_course (ends_on yesterday) fixtures

## Decisions Made

- **Scope-based auto-archive:** `active_courses` uses SQL time comparison (`ends_on >= Date.today`) — no background job, no `archived` boolean column needed
- **Course exclusion at query level:** `.where(course: false)` chained in both controller queries, not just relying on `low_stock?` returning false — excludes course records from DB loading entirely
- **`with_options if: :course?` for conditional validations:** Keeps validation logic explicit; non-course medications are unaffected
- **`ends_on` must be strictly after `starts_on`:** Equal dates represent a zero-duration course which is meaningless; `<=` check used in validation
- **`low_stock?` returns false for `course_active?`:** Active courses are short-lived prescriptions; stock level alerts are not applicable while the course is running
- **Index on `ends_on`:** Scope queries filter by `ends_on` frequently; per locked user decision

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All data and business logic for temporary medication courses is complete and stable
- `active_courses`, `archived_courses`, `non_courses` scopes and `course_active?` predicate are ready for UI consumption in Phase 18-02
- Column names (`course`, `starts_on`, `ends_on`) are locked; Phase 18-02 UI plan can rely on them
- 410 tests passing, no regressions

## Self-Check: PASSED

All files found, commits verified, key patterns confirmed:
- Migration: `db/migrate/20260310191313_add_course_fields_to_medications.rb` — FOUND
- Model: `app/models/medication.rb` — FOUND (active_courses scope present)
- Controllers: `dashboard_controller.rb` (2x `.where(course: false)`), `adherence_controller.rb` (1x) — FOUND
- Tests: `test/models/medication_test.rb` — FOUND
- Fixtures: `test/fixtures/medications.yml` — FOUND
- SUMMARY: `18-01-SUMMARY.md` — FOUND
- Commits: `489801e` and `c5d890b` — FOUND

---
*Phase: 18-temporary-medication-courses*
*Completed: 2026-03-10*
