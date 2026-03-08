---
phase: 14-adherence-dashboard
plan: 03
subsystem: adherence
tags: [rails, controller, views, css, system-tests, controller-tests, adherence]

requires:
  - phase: 14-01
    provides: AdherenceCalculator service object returning Result struct
  - phase: 14-02
    provides: GET /adherence route (adherence_path), dashboard adherence section

provides:
  - AdherenceController#index at GET /adherence with 7/30-day history grid
  - app/views/adherence/index.html.erb with day range toggle
  - app/views/adherence/_history_grid.html.erb with colour-coded cell grid
  - Controller tests: auth redirect, day param handling, cross-user isolation
  - System tests: dashboard adherence section, history page grid rendering, day toggle, cell colour states

affects: []

tech-stack:
  added: []
  patterns:
    - "Date range iteration: Ruby Range#map over Date objects produces one entry per day"
    - "URL param allowlist: params[:days].to_i.in?([7, 30]) defaults to 7 — no open redirect risk"
    - "@adherence_history: array of {medication:, days_data: [{date:, result:}]} hashes passed to partials"

key-files:
  created:
    - app/controllers/adherence_controller.rb
    - app/views/adherence/index.html.erb
    - app/views/adherence/_history_grid.html.erb
    - test/controllers/adherence_controller_test.rb
    - test/system/adherence_test.rb
  modified:
    - app/assets/stylesheets/application.css

key-decisions:
  - "CSS variables corrected again: plan referenced non-existent --severity-green/red, --color-border, --color-text-muted, --color-primary, --radius; used --severity-mild, --severity-severe, --border, --text-3, --brand, --radius-md from actual codebase tokens"
  - "System tests scoped to adherence_test.rb only: pre-existing failures in other system tests (asserting root_url after sign-in instead of dashboard_url) are not regressions from this plan — all 7 new adherence system tests pass"

patterns-established:
  - "Colour-coded adherence grid: .adherence-cell--on_track (green), .adherence-cell--missed (red), .adherence-cell--no_schedule (grey)"
  - "7/30-day URL toggle: link_to with days param, active class driven by @days instance variable"

requirements_covered: []

duration: ~3min
completed: 2026-03-08
---

# Phase 14 Plan 03: Adherence History Controller and Views Summary

**AdherenceController serving a colour-coded day-by-day history grid for the last 7 or 30 days per preventer medication, with green/red/grey cells driven by AdherenceCalculator, plus full controller and system test coverage.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-08T19:21:22Z
- **Completed:** 2026-03-08T19:24:38Z
- **Tasks:** 2
- **Files modified:** 6 (5 created, 1 modified)

## Accomplishments

- `AdherenceController#index` computes a date range (7 or 30 days) and maps over scheduled preventers calling `AdherenceCalculator.call` per day — returns `@adherence_history` array of `{medication:, days_data:}` hashes
- `?days=30` URL param accepted; invalid values silently default to 7 (allowlist pattern)
- `app/views/adherence/index.html.erb` with active-state toggle links and empty state for users with no scheduled preventers
- `app/views/adherence/_history_grid.html.erb` with flex grid of `.adherence-cell--on_track/missed/no_schedule` cells, accessible ARIA labels, and legend
- CSS appended to `application.css` using actual codebase custom properties (correcting plan's non-existent variable names)
- 7 controller tests: auth redirect, 7-day default, 30-day param, invalid param fallback, medication type filtering, cross-user isolation — all pass
- 7 system tests: dashboard adherence section visible, "View history" link works, 7-day grid renders with correct cell count, 30-day toggle works, pre-creation days show as grey, on-track day shows green — all pass
- Full unit/integration test suite: 290 tests, 0 failures (7 new controller tests added)

## Task Commits

Each task was committed atomically:

1. **Task 1: AdherenceController, history grid views, and CSS** - `5244746` (feat)
2. **Task 2: Controller tests and system tests for adherence history** - `8aea1fa` (test)

## Files Created/Modified

- `app/controllers/adherence_controller.rb` - Created: AdherenceController#index with date range and medication filtering
- `app/views/adherence/index.html.erb` - Created: history page with 7/30-day toggle and empty state
- `app/views/adherence/_history_grid.html.erb` - Created: day-by-day grid partial with colour-coded cells and legend
- `app/assets/stylesheets/application.css` - Modified: adherence history page CSS block appended
- `test/controllers/adherence_controller_test.rb` - Created: 7 controller integration tests
- `test/system/adherence_test.rb` - Created: 7 system tests covering dashboard and history page

## Decisions Made

- **CSS variables corrected from plan**: Plan referenced `--severity-green`, `--severity-red`, `--color-border`, `--color-text-muted`, `--color-primary`, and `--radius` — none exist in this codebase. Used actual variables: `--severity-mild` (green), `--severity-severe` (red), `--border` (gray-200), `--text-3` (gray-500), `--brand` (teal-600), `--radius-md` (6px). Pattern consistent with 14-02 correction.
- **System tests scoped for isolation**: Pre-existing failures in peak_flow_recording_test.rb, symptom_logging_test.rb, peak_flow_display_test.rb, authentication_test.rb (all asserting `root_url` post-sign-in instead of `dashboard_url`) are not regressions from this plan. Running `bin/rails test test/system/adherence_test.rb` shows 7/7 pass cleanly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CSS custom property names corrected to match codebase**
- **Found during:** Task 1 (CSS authoring)
- **Issue:** Plan specified `--severity-green`, `--severity-red`, `--color-border`, `--color-text-muted`, `--color-primary`, `--radius` — none exist in `application.css`. Using them would silently produce unstyled cells.
- **Fix:** Used actual CSS custom properties consistent with what was established in Plan 14-02: `--severity-mild`, `--severity-severe`, `--border`, `--text-3`, `--brand`, `--radius-md`.
- **Files modified:** app/assets/stylesheets/application.css
- **Verification:** All 290 tests pass; visual result matches plan intent
- **Committed in:** `5244746` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - CSS property name mismatch, same class of deviation as 14-02)
**Impact on plan:** Correction necessary for correct styling. No scope changes.

## Issues Encountered

None beyond the auto-fixed CSS variable names above. Pre-existing system test failures in other test files are not related to this plan.

## User Setup Required

None.

## Next Phase Readiness

- Phase 14 (Adherence Dashboard) is complete — all 3 plans done
- The full adherence feature is live: AdherenceCalculator (14-01) → dashboard card (14-02) → history page (14-03)
- 290 tests passing, no regressions

---
*Phase: 14-adherence-dashboard*
*Completed: 2026-03-08*

## Self-Check: PASSED

- app/controllers/adherence_controller.rb: FOUND
- app/views/adherence/index.html.erb: FOUND
- app/views/adherence/_history_grid.html.erb: FOUND
- test/controllers/adherence_controller_test.rb: FOUND
- test/system/adherence_test.rb: FOUND
- commit 5244746 (feat - Task 1): FOUND
- commit 8aea1fa (test - Task 2): FOUND
