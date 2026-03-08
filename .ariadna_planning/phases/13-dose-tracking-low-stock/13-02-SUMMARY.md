---
phase: 13-dose-tracking-low-stock
plan: 02
subsystem: ui
tags: [rails, turbo-streams, turbo-frames, hotwire, medications, settings]

# Dependency graph
requires:
  - phase: 13-01
    provides: low_stock? predicate, medication card with remaining_doses and days_of_supply_remaining, dashboard Medications section

provides:
  - PATCH /settings/medications/:id/refill route (refill_settings_medication_path)
  - Settings::MedicationsController#refill action updating starting_dose_count and refilled_at
  - <details>/<summary> inline refill form on medication card partial
  - refill.turbo_stream.erb replacing full medication card frame and flash on success
  - Cross-user refill blocked by set_medication scoping via Current.user

affects: [future dose tracking phases, medication management]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "details/summary HTML element for zero-JS toggle form — accessible, no Stimulus needed"
    - "Turbo Stream replace full medication card frame after refill to reset form state and refresh counts"
    - "flash.now[:notice] set before respond_to so turbo_stream views receive flash value"

key-files:
  created:
    - app/views/settings/medications/refill.turbo_stream.erb
  modified:
    - config/routes.rb
    - app/controllers/settings/medications_controller.rb
    - app/views/settings/medications/_medication.html.erb
    - app/views/dashboard/index.html.erb

key-decisions:
  - "Dashboard Refill link points to settings_medications_path (not refill route) because refill_settings_medication_path is PATCH-only; the inline form on the card handles the actual refill"
  - "details/summary pattern chosen over Stimulus toggle or Turbo Frame src approach — zero JS, native browser accessibility, collapses automatically when card re-renders via Turbo Stream"
  - "refill.turbo_stream.erb replaces full medication card frame (dom_id(@medication)) rather than individual remaining_count span — ensures form resets to closed state and all computed fields update atomically"

patterns-established:
  - "Refill authorization via set_medication before_action scoped to Current.user.medications.find — RecordNotFound returns 404, no separate authorization step needed"
  - "refill_params independent strong params method — only :starting_dose_count permitted, not mixed with medication_params"

requirements_covered: []

# Metrics
duration: 8min
completed: 2026-03-08
---

# Phase 13 Plan 02: Dose Tracking Low Stock — Refill Action Summary

**PATCH /settings/medications/:id/refill with details/summary inline form, Turbo Stream card refresh, and cross-user 404 via Current.user scope**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-08T18:22:23Z
- **Completed:** 2026-03-08T18:30:00Z
- **Tasks:** 2
- **Files modified:** 5 (4 modified, 1 created)

## Accomplishments
- Refill route (`PATCH /settings/medications/:id/refill`) added; cross-user attempts return 404 automatically via `Current.user.medications.find`
- `Settings::MedicationsController#refill` updates `starting_dose_count` and `refilled_at`, sets `flash.now[:notice]` before `respond_to`
- Inline refill form on medication card using `<details>/<summary>` — zero JavaScript, accessible, pre-filled with current `starting_dose_count`
- Turbo Stream response re-renders full medication card frame and flash — resets form to closed state, refreshes remaining doses and low-stock badge atomically

## Task Commits

Each task was committed atomically:

1. **Task 1: Add refill route and action to Settings::MedicationsController** - `903216c` (feat)
2. **Task 2: Add inline refill form to medication card and Turbo Stream response view** - `d5d2650` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `config/routes.rb` - Added `patch :refill` member route inside medications resources block
- `app/controllers/settings/medications_controller.rb` - Added `refill` action and `refill_params` private method; added `refill` to `set_medication` before_action
- `app/views/settings/medications/_medication.html.erb` - Added `<details class="refill-details">` with inline form pre-filled from `medication.starting_dose_count`
- `app/views/settings/medications/refill.turbo_stream.erb` - Created: replaces `dom_id(@medication)` frame and `flash-messages`
- `app/views/dashboard/index.html.erb` - Updated dashboard "Refill" link from `settings_medication_path` to `settings_medications_path` (refill route is PATCH-only)

## Decisions Made
- **Dashboard Refill link target:** `refill_settings_medication_path` is PATCH-only — no GET counterpart. The dashboard "Refill" link was updated to `settings_medications_path` so users navigate to the settings page where the inline form is available.
- **details/summary chosen over Turbo Frame toggle:** No extra route, no Stimulus controller, native browser accessibility. Form resets to closed automatically when Turbo Stream replaces the card.
- **Full card frame replacement in Turbo Stream:** Replacing `dom_id(@medication)` (the outer turbo_frame_tag) re-renders all computed fields (`remaining_doses`, `days_of_supply_remaining`, `low_stock?`) and resets the `<details>` element to closed in one operation.

## Deviations from Plan

None — plan executed exactly as written. The dashboard link target clarification (PATCH-only route cannot be a `link_to` target) was noted in the plan itself and implemented as `settings_medications_path`.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 13 complete: low_stock? predicate, medication card badge/days-of-supply, dashboard Medications section, and refill action all delivered
- 267 tests passing, no regressions
- Milestone 2 Medication & Compliance feature set complete for dose tracking

## Self-Check: PASSED

All files verified present on disk. All task commits verified in git log.

- config/routes.rb: FOUND
- app/controllers/settings/medications_controller.rb: FOUND
- app/views/settings/medications/_medication.html.erb: FOUND
- app/views/settings/medications/refill.turbo_stream.erb: FOUND
- app/views/dashboard/index.html.erb: FOUND
- .ariadna_planning/phases/13-dose-tracking-low-stock/13-02-SUMMARY.md: FOUND
- Commit 903216c: FOUND
- Commit d5d2650: FOUND

---
*Phase: 13-dose-tracking-low-stock*
*Completed: 2026-03-08*
