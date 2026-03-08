---
phase: 14-adherence-dashboard
plan: 02
subsystem: dashboard
tags: [rails, dashboard, adherence, erb, css, routing]

requires:
  - phase: 14-01
    provides: AdherenceCalculator service object returning Result struct

provides:
  - DashboardController#index assigns @preventer_adherence array
  - app/views/dashboard/_adherence_card.html.erb partial for per-preventer adherence
  - Dashboard adherence section with on-track/missed visual states
  - GET /adherence route (adherence_path) for Plan 14-03

affects:
  - 14-03-adherence-history-controller

tech-stack:
  added: []
  patterns:
    - "Dashboard service integration: controller maps over filtered medications calling AdherenceCalculator.call"
    - "Partial rendering: render 'dashboard/adherence_card', medication:, result: passing Result struct to ERB"
    - "CSS status modifier classes: dash-adherence-item--on_track / --missed driven by result.status symbol"

key-files:
  created:
    - app/views/dashboard/_adherence_card.html.erb
  modified:
    - app/controllers/dashboard_controller.rb
    - app/views/dashboard/index.html.erb
    - app/assets/stylesheets/application.css
    - config/routes.rb

key-decisions:
  - "CSS variables corrected from plan: --severity-mild (green) and --severity-severe (red) used instead of non-existent --severity-green/--severity-red; --surface/--border/--text-3 used instead of --color-surface/--color-border/--color-text-muted; --radius-md used instead of --radius"
  - "adherence route added to routes.rb in 14-02 (not 14-03) as specified by plan — ready for AdherenceController creation in next plan"

duration: 2min
completed: 2026-03-08
---

# Phase 14 Plan 02: Dashboard Adherence Section Summary

**Dashboard adherence section showing each scheduled preventer's N/N taken today with green on-track and red missed visual states, backed by AdherenceCalculator and rendered via a dedicated partial.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-08T19:17:57Z
- **Completed:** 2026-03-08T19:19:09Z
- **Tasks:** 2
- **Files modified:** 5 (4 modified, 1 created)

## Accomplishments

- `DashboardController#index` builds `@preventer_adherence` — array of `{medication:, result:}` hashes filtered to preventer type with `doses_per_day.present?`
- `_adherence_card.html.erb` partial renders `result.taken / result.scheduled` with aria-label; conditional label text for on_track vs missed state
- `dashboard/index.html.erb` shows adherence section above low-stock medications when `@preventer_adherence.any?`; links to `adherence_path`
- GET `/adherence` route added as `adherence_path` (ready for Plan 14-03 AdherenceController)
- CSS for `.dash-adherence-item--on_track` (green left border + count colour) and `.dash-adherence-item--missed` (red left border + count colour)
- Full test suite: 283 tests passing, 0 failures, 0 regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: Load today's preventer adherence in DashboardController** - `4809419` (feat)
2. **Task 2: Dashboard adherence section — partial and view integration** - `66e6221` (feat)

## Files Created/Modified

- `app/views/dashboard/_adherence_card.html.erb` — Created: partial for single preventer adherence card
- `app/controllers/dashboard_controller.rb` — Modified: added @preventer_adherence query after @low_stock_medications
- `app/views/dashboard/index.html.erb` — Modified: added adherence section above low-stock section
- `app/assets/stylesheets/application.css` — Modified: added dash-adherence CSS block with on_track/missed states
- `config/routes.rb` — Modified: added `get "adherence", to: "adherence#index", as: :adherence`

## Decisions Made

- **CSS variables corrected from plan**: Plan referenced `--severity-green`, `--severity-red`, `--color-surface`, `--color-border`, `--color-text-muted`, and `--radius` which do not exist in this codebase. Used actual variables: `--severity-mild` (green), `--severity-severe` (red), `--surface`, `--border`, `--text-3`, and `--radius-md`.
- **adherence route pre-registered in 14-02**: The plan specified adding the route now so `adherence_path` resolves in the dashboard view even before AdherenceController exists in 14-03.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CSS custom property names corrected to match codebase**
- **Found during:** Task 2 (CSS authoring)
- **Issue:** Plan specified `--severity-green`, `--severity-red`, `--color-surface`, `--color-border`, `--color-text-muted`, `--radius` — none of these variables exist in `application.css`. Using them would silently produce unstyled cards.
- **Fix:** Used actual CSS custom properties: `--severity-mild` (#16a34a, green), `--severity-severe` (#dc2626, red), `--surface` (#ffffff), `--border` (gray-200), `--text-3` (gray-500), `--radius-md` (6px).
- **Files modified:** app/assets/stylesheets/application.css
- **Verification:** All 283 tests pass; CSS variables verified against `:root` definitions in application.css
- **Committed in:** `66e6221` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - CSS property name mismatch between plan and codebase)
**Impact on plan:** Correction necessary for correct styling. Variables referenced in plan were aliases that don't exist — using actual tokens produces identical visual result intended by the plan.

## Issues Encountered

None beyond the auto-fixed CSS variable names above.

## User Setup Required

None.

## Next Phase Readiness

- `adherence_path` route is registered and resolves — Plan 14-03 can create `AdherenceController#index` without any routing changes
- `@preventer_adherence` array structure (`{medication:, result:}` with `AdherenceCalculator::Result`) is established — consistent interface for 14-03 history page
- No blockers

---
*Phase: 14-adherence-dashboard*
*Completed: 2026-03-08*
