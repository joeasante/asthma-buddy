---
phase: 12-dose-logging
plan: 02
subsystem: views
tags: [rails, turbo-streams, erb, medication-cards, dose-logging, n+1-fix]

# Dependency graph
requires:
  - phase: 12-01
    provides: Settings::DoseLogsController with create and destroy + nested routes
  - phase: 11-medication-management-ui
    provides: _medication.html.erb card partial, Settings::MedicationsController pattern
  - phase: 10-medication-model
    provides: Medication.remaining_doses, DoseLog model, chronological scope
provides:
  - Inline dose log form on each medication card (settings/dose_logs/_form.html.erb)
  - Dose log row partial with delete button (settings/dose_logs/_dose_log.html.erb)
  - Turbo Stream create response: updates dose history, remaining count, resets form
  - Turbo Stream destroy response: updates dose history, remaining count
  - Updated medication card with Remaining count cell (id=remaining_count_*) and dose history section (id=dose_history_*)
  - N+1 fix on MedicationsController#index via .includes(:dose_logs)
affects: [12-03-dose-logging-tests]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Turbo Stream replace targeting id=dose_history_{dom_id}, id=remaining_count_{dom_id}, id=dose_log_form_{dom_id}"
    - "DoseLog.new(medication: medication) in view — not medication.dose_logs.new — to avoid pushing unsaved record into eager-loaded association array (MEMORY.md safety)"
    - "medication.dose_logs.sort_by(&:recorded_at).reverse.first(5) — Ruby-side sort on eager-loaded records, zero DB queries"
    - "flash.now[:notice] before respond_to for Turbo Stream success paths"

key-files:
  created:
    - app/views/settings/dose_logs/_form.html.erb
    - app/views/settings/dose_logs/_dose_log.html.erb
    - app/views/settings/dose_logs/create.turbo_stream.erb
    - app/views/settings/dose_logs/destroy.turbo_stream.erb
  modified:
    - app/controllers/settings/medications_controller.rb
    - app/views/settings/medications/_medication.html.erb
    - app/controllers/settings/dose_logs_controller.rb

key-decisions:
  - "DoseLog.new(medication:) not medication.dose_logs.new in views — avoids pushing unsaved record into eager-loaded in-memory array (MEMORY.md rule)"
  - "Ruby-side sort for recent_logs on index: sort_by(&:recorded_at).reverse.first(5) uses eager-loaded association, zero additional DB queries"
  - "create.turbo_stream.erb re-queries via @medication.dose_logs.chronological.limit(5) — fresh SQL post-save guarantees correct order including new record"
  - "flash.now[:notice] set before respond_to in DoseLogsController create/destroy so Turbo Stream flash partial receives it"
  - ".includes(:dose_logs) added to MedicationsController#index to prevent N+1 when rendering dose history on each card"

# Metrics
duration: ~1min
completed: 2026-03-08
---

# Phase 12 Plan 02: Dose Logging Views Summary

**Inline dose log form and history section on each medication card with Turbo Stream responses replacing dose history, remaining count, and form after create/destroy**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-08T17:39:08Z
- **Completed:** 2026-03-08T17:40:08Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Fixed N+1: `MedicationsController#index` now uses `.includes(:dose_logs)` — dose history renders without hitting DB per card
- Created `settings/dose_logs/_form.html.erb`: puffs field pre-filled from `standard_dose_puffs`, recorded_at pre-filled to `Time.current`, form id targets Turbo Stream replacement
- Created `settings/dose_logs/_dose_log.html.erb`: dose log row with puffs, formatted timestamp, delete button with custom confirm dialog
- Updated `_medication.html.erb`: added Remaining count `<dd>` with `id="remaining_count_*"`, dose log section embedding form partial, dose history section with `id="dose_history_*"`
- Created `create.turbo_stream.erb`: four `turbo_stream.replace` calls — dose history, remaining count, form reset, flash
- Created `destroy.turbo_stream.erb`: three `turbo_stream.replace` calls — dose history, remaining count, flash
- Updated `DoseLogsController`: `flash.now[:notice]` set before `respond_to` in both create and destroy success paths
- All 256 existing tests pass with no regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: N+1 fix on medications index + dose log view partials** - `376d2d8` (feat)
2. **Task 2: Medication card with dose log form + Turbo Stream responses** - `2996872` (feat)

## Files Created/Modified

- `app/controllers/settings/medications_controller.rb` - Added `.includes(:dose_logs)` to index query
- `app/views/settings/dose_logs/_form.html.erb` - New: inline dose log form with puffs (pre-filled) and recorded_at fields
- `app/views/settings/dose_logs/_dose_log.html.erb` - New: dose log row with delete button
- `app/views/settings/medications/_medication.html.erb` - Updated: added Remaining dd with id, dose log section, dose history section
- `app/views/settings/dose_logs/create.turbo_stream.erb` - New: replaces dose history + remaining count + form + flash
- `app/views/settings/dose_logs/destroy.turbo_stream.erb` - New: replaces dose history + remaining count + flash
- `app/controllers/settings/dose_logs_controller.rb` - Added flash.now[:notice] for Turbo Stream success paths

## Decisions Made

- `DoseLog.new(medication: medication)` used in `_medication.html.erb` (not `medication.dose_logs.new`) — consistent with MEMORY.md safety rule: avoids pushing unsaved record into eager-loaded in-memory association array which would corrupt remaining dose calculations on any subsequent `medication.save`
- Ruby-side sort on eager-loaded `dose_logs` association for the index view: `sort_by(&:recorded_at).reverse.first(5)` — zero additional queries because the association is already loaded via `includes(:dose_logs)` in the controller
- Turbo Stream responses query fresh via `@medication.dose_logs.chronological.limit(5)` to guarantee correct post-save SQL ordering
- Flash via `turbo_stream.replace "flash-messages"` — consistent with Phase 11 precedent; non-accumulating pattern

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All Turbo Stream view files and DOM IDs are in place; Plan 12-03 can now add integration and system tests for the full log-a-dose workflow
- No blockers.

---
*Phase: 12-dose-logging*
*Completed: 2026-03-08*

## Self-Check: PASSED

- FOUND: app/controllers/settings/medications_controller.rb (includes :dose_logs)
- FOUND: app/views/settings/dose_logs/_form.html.erb
- FOUND: app/views/settings/dose_logs/_dose_log.html.erb
- FOUND: app/views/settings/medications/_medication.html.erb (remaining_count_ and dose_history_ ids)
- FOUND: app/views/settings/dose_logs/create.turbo_stream.erb (4 turbo_stream.replace calls)
- FOUND: app/views/settings/dose_logs/destroy.turbo_stream.erb (3 turbo_stream.replace calls)
- FOUND: app/controllers/settings/dose_logs_controller.rb (flash.now[:notice])
- FOUND: commit 376d2d8 (Task 1)
- FOUND: commit 2996872 (Task 2)
- 256 tests, 0 failures, 0 errors
