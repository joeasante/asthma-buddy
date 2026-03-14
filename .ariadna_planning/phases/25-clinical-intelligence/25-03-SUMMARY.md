---
phase: 25-clinical-intelligence
plan: 03
subsystem: ui
tags: [rails, erb, css, print-layout, appointment-summary, clinical-detail]

# Dependency graph
requires:
  - phase: 25-clinical-intelligence-02
    provides: "Appointment summary page with aggregate stats, 5 data sections, print button"
provides:
  - "Individual record detail tables in appointment summary (peak flow, symptoms, reliever doses, health events)"
  - "Print-optimised layout with page-break rules and reduced spacing"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "appt-detail-table class for individual record listings below aggregate stats"
    - "with_rich_text_notes eager loading for Action Text associations in read-only views"
    - "SQL select with AS aliases for cross-table joins (dose_logs + medications)"

key-files:
  created: []
  modified:
    - app/controllers/appointment_summaries_controller.rb
    - app/views/appointment_summaries/show.html.erb
    - app/assets/stylesheets/appointment_summary.css
    - test/controllers/appointment_summaries_controller_test.rb

key-decisions:
  - "Kept aggregate stats alongside detail tables rather than replacing them"
  - "Used SQL select with AS for dose log join to avoid N+1 without preloading full medication records"
  - "Health events ordered desc (most recent first) for GP readability"

patterns-established:
  - "appt-detail-table: compact table style for individual clinical records"
  - "break-inside:avoid on sections, break-inside:auto on long tables with per-row avoid"

# Metrics
duration: 4min
completed: 2026-03-14
---

# Phase 25 Plan 03: Appointment Summary Detail Tables

**Individual-level peak flow, symptom, reliever dose, and health event detail tables with print-optimised page-break rules**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-14
- **Completed:** 2026-03-14
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Controller loads individual records (@individual_readings, @symptom_logs, @dose_logs_with_meds) alongside existing aggregates
- View renders detail tables with dates, values, types, notes in each of the 5 sections
- Print layout fixed: reduced font-size (10pt), header spacing, section card padding; added break-inside:avoid, orphans/widows
- 3 new tests added (individual readings, symptom records, dose log details); 564 total tests pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Load individual records and render detail tables** - `9dceb44` (feat)
2. **Task 2: Detail table CSS, print layout fixes, and tests** - `935bc15` (feat)

## Files Created/Modified
- `app/controllers/appointment_summaries_controller.rb` - Added @individual_readings, @symptom_logs, @dose_logs_with_meds; updated @health_events with desc order and rich text eager loading
- `app/views/appointment_summaries/show.html.erb` - Added 4 detail tables (peak flow, symptoms, reliever doses, health events with duration/notes)
- `app/assets/stylesheets/appointment_summary.css` - Added .appt-detail-table/.appt-detail-heading/.appt-notes-cell styles; replaced print block with reduced spacing and page-break rules
- `test/controllers/appointment_summaries_controller_test.rb` - 3 new tests for individual record rendering

## Decisions Made
- Kept all existing aggregate stats and added detail tables below them (not replacing)
- Used SQL select with AS aliases for dose_logs join to medications (avoids N+1 without full model preload)
- Changed health events order to desc (most recent first) for GP utility

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Appointment summary now shows full clinical detail for GP consultations
- Print layout optimised with efficient page usage

## Self-Check: PASSED

- All 5 files verified present on disk
- Both task commits (9dceb44, 935bc15) verified in git log
- @individual_readings confirmed in controller
- appt-detail-table confirmed in view
- break-inside confirmed in CSS
- 564 tests pass, 0 failures

---
*Phase: 25-clinical-intelligence*
*Completed: 2026-03-14*
