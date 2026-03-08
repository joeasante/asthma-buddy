---
phase: 13-dose-tracking-low-stock
plan: 01
subsystem: ui
tags: [rails, medication, low-stock, dashboard, activerecord]

# Dependency graph
requires:
  - phase: 12-dose-logging
    provides: DoseLog model and dose_logs association used by remaining_doses/days_of_supply_remaining
  - phase: 10-medication-model
    provides: Medication model with remaining_doses and days_of_supply_remaining methods
provides:
  - Medication::LOW_STOCK_DAYS = 14 constant
  - Medication#low_stock? predicate (false when doses_per_day nil)
  - Medication card shows ~X days remaining and Low stock badge conditionally
  - Dashboard @low_stock_medications query and Medications section
affects:
  - 13-02 (refill route — Refill link on dashboard already points to settings_medication_path)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "includes(:dose_logs).select(&:low_stock?) — eager load then filter in Ruby to avoid N+1"
    - "LOW_STOCK_DAYS constant on model — threshold defined once, referenced by predicate"

key-files:
  created: []
  modified:
    - app/models/medication.rb
    - app/views/settings/medications/_medication.html.erb
    - app/controllers/dashboard_controller.rb
    - app/views/dashboard/index.html.erb
    - app/assets/stylesheets/settings.css
    - app/assets/stylesheets/dashboard.css

key-decisions:
  - "low_stock? returns false when doses_per_day is nil — reliever inhalers with no schedule must never trigger the 14-day warning"
  - "includes(:dose_logs).select(&:low_stock?) in controller — one query loads all medications with logs, Ruby-side filter avoids N+1 since low_stock? calls remaining_doses which sums dose_logs"
  - "Dashboard Medications section absent when @low_stock_medications.any? is false — no empty-state needed"

patterns-established:
  - "Predicate guards nil from days_of_supply_remaining before threshold comparison"
  - "Conditional class on article element for low-stock visual highlight"

# Metrics
duration: 10min
completed: 2026-03-08
---

# Phase 13 Plan 01: Low-Stock Tracking Summary

**Medication::LOW_STOCK_DAYS = 14 constant and low_stock? predicate added; medication cards show ~X days remaining and Low stock badge; dashboard Medications section surfaces low-stock medications.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-08T00:00:00Z
- **Completed:** 2026-03-08T00:10:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `LOW_STOCK_DAYS = 14` and `low_stock?` predicate to Medication model — guards nil from `days_of_supply_remaining` so relievers without `doses_per_day` never trigger warning
- Updated medication card partial to show `~X days remaining` (when `doses_per_day` present) and `Low stock` badge (when `low_stock?` true), preserving existing Turbo Stream target IDs
- Added `@low_stock_medications` query to `DashboardController#index` via `includes(:dose_logs).select(&:low_stock?)` and rendered conditional Medications section in dashboard view
- Added CSS: `.low-stock-badge`, `.medication-days-supply`, `.medication-card--low-stock` in settings.css; `.dash-medications`, `.dash-low-stock-*` in dashboard.css

## Task Commits

1. **Task 1: Add LOW_STOCK_DAYS constant and low_stock? predicate** - `f4aecb1` (feat)
2. **Task 2: Medication card, dashboard controller, dashboard view, CSS** - `c1f0d4b` (feat)

## Files Created/Modified

- `app/models/medication.rb` - Added `LOW_STOCK_DAYS = 14` and `low_stock?` predicate
- `app/views/settings/medications/_medication.html.erb` - Days-of-supply text and low-stock badge inside remaining-count dd; conditional article class
- `app/controllers/dashboard_controller.rb` - `@low_stock_medications` via includes/select
- `app/views/dashboard/index.html.erb` - Medications section with low-stock list, between dash-stats and dash-quick-log
- `app/assets/stylesheets/settings.css` - `.low-stock-badge`, `.medication-days-supply`, `.medication-card--low-stock` styles
- `app/assets/stylesheets/dashboard.css` - `.dash-medications`, `.dash-low-stock-list/item/name/supply/refill-link` styles

## Decisions Made

- `low_stock?` returns false when `doses_per_day` is nil — reliever inhalers with no schedule must never trigger the 14-day warning (locked decision from CONTEXT.md)
- `includes(:dose_logs).select(&:low_stock?)` in controller — one SQL query loads all medications with their dose logs; Ruby-side `select` avoids N+1 since `low_stock?` calls `remaining_doses` which calls `dose_logs.sum` (computed in Ruby from already-loaded records)
- Dashboard Medications section uses `@low_stock_medications.any?` guard — section absent when no medications are low stock, no empty-state rendering needed

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Low-stock predicate and dashboard surface complete; Plan 02 can add the refill route and update the Refill link from `settings_medication_path` to the dedicated refill endpoint
- All 267 tests passing, no regressions

---
*Phase: 13-dose-tracking-low-stock*
*Completed: 2026-03-08*
