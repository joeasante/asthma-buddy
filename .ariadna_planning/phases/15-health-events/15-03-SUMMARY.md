---
phase: 15-health-events
plan: 03
subsystem: ui
tags: [rails, chart.js, stimulus, javascript, dashboard, health-events]

# Dependency graph
requires:
  - phase: 15-01
    provides: HealthEvent model with event_type enum, event_type_css_modifier, and health_events association on User
provides:
  - DashboardController assigns @health_event_markers filtered to 7-day chart window
  - Canvas element receives data-chart-health-events-value JSON attribute
  - chart_controller.js afterDraw plugin draws dashed vertical marker lines per event on peakflow-bands chart
  - System test confirming dashboard chart section carries correct marker JSON
affects: [future chart enhancements, dashboard UI changes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Chart.js inline plugin pattern: register via plugins array in new Chart() call, not Chart.register()"
    - "dateLabelMap bridge: translate ISO dates to chart x-axis label strings via toDayLabel() before pixel lookup"
    - "Controller test avoids assigns() gem by asserting HTML attribute content directly via assert_select block"
    - "System test creates inline PeakFlowReading to guarantee chart section renders when fixture window may not cover today"

key-files:
  created: []
  modified:
    - app/controllers/dashboard_controller.rb
    - app/views/dashboard/index.html.erb
    - app/javascript/controllers/chart_controller.js
    - test/controllers/dashboard_controller_test.rb
    - test/system/medical_history_test.rb

key-decisions:
  - "assigns() unavailable without rails-controller-testing gem: rewrote controller tests to assert HTML attribute content via assert_select block and JSON.parse instead"
  - "Chart section requires @chart_data.any? to render canvas: tests that assert canvas attributes must create a PeakFlowReading within the current week inline"
  - "dateLabelMap lookup bridges ISO date string to toDayLabel() output ('Sat 7') so xAxis.getPixelForValue() resolves the correct pixel position"
  - "markerPlugin passed as plugins: [markerPlugin] top-level Chart.js key alongside type/data/options — not Chart.register() which would apply globally"

patterns-established:
  - "Chart.js afterDraw plugin: access chart.scales.x.getPixelForValue(label) with the label string (not the raw data value) to get x pixel"
  - "eventMarkerColor() helper: hardcoded hex map keyed on css_modifier string (e.g. 'gp-appointment' not 'gp_appointment')"

requirements_covered:
  - id: "EVT-03"
    description: "Health event markers overlaid on 7-day peak flow chart"
    evidence: "app/javascript/controllers/chart_controller.js markerPlugin, app/controllers/dashboard_controller.rb @health_event_markers"

# Metrics
duration: 15min
completed: 2026-03-09
---

# Phase 15 Plan 03: Health Event Chart Markers Summary

**Chart.js afterDraw plugin draws colour-coded dashed vertical lines per health event on the dashboard 7-day peak flow chart, with ISO-to-label bridging via dateLabelMap and no new gems or importmap pins.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-09T15:30:00Z
- **Completed:** 2026-03-09T15:45:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- `DashboardController` assigns `@health_event_markers` — array of `{date, type, label, css_modifier}` hashes filtered to the current Monday–today window
- Dashboard canvas receives `data-chart-health-events-value` JSON attribute alongside existing chart data
- `chart_controller.js` registers inline `healthEventMarkers` afterDraw plugin in `renderPeakFlowBandsChart` only; other chart renderers unchanged
- Markers are dashed vertical lines (1.5px, 75% opacity) colour-coded by event type, labelled with short abbreviations (GP, Hosp, Ill, Rx, Evt)
- System test confirms dashboard canvas carries correct marker JSON when a health event is in the chart window

## Requirements Covered

| REQ-ID | Requirement | Evidence |
|--------|-------------|----------|
| EVT-03 | Health event markers on 7-day peak flow chart | `DashboardController#@health_event_markers`, `chart_controller.js markerPlugin` |

## Task Commits

Each task was committed atomically:

1. **Task 1: DashboardController + view wiring** - `cd65460` (feat)
2. **Task 2: chart_controller.js afterDraw plugin** - `804474a` (feat)

_System test for Task 2 was committed as part of the phase 15-02 system test commit (`53d2ac6`) due to stash pop timing; the test body is identical to the plan spec._

## Files Created/Modified

- `app/controllers/dashboard_controller.rb` - Adds `@health_event_markers` query, `MARKER_LABELS` constant, `event_marker_label` private helper
- `app/views/dashboard/index.html.erb` - Canvas element gains `data-chart-health-events-value` attribute
- `app/javascript/controllers/chart_controller.js` - `healthEvents: Array` in static values; `eventMarkerColor()` helper; `markerPlugin` afterDraw plugin in `renderPeakFlowBandsChart`
- `test/controllers/dashboard_controller_test.rb` - 4 new tests: success response, windowing exclusion, expected keys, canvas attribute
- `test/system/medical_history_test.rb` - Chart marker integration test appended

## Decisions Made

- **`assigns()` unavailable without `rails-controller-testing` gem:** Rewrote the three tests that called `assigns(:health_event_markers)` to instead assert on the rendered HTML attribute content using `assert_select "canvas[data-chart-health-events-value]"` blocks and `JSON.parse`. This is the standard approach for Rails apps without that gem.

- **Canvas only renders when `@chart_data.any?`:** Tests that assert `data-chart-health-events-value` must ensure at least one PeakFlowReading exists within the current Monday–today window. The `alice_green_reading` and `alice_yellow_reading` fixtures are 2 and 1 days ago respectively — on a Monday these fall before `beginning_of_week(:monday)`. Tests now create a `PeakFlowReading` inline at `beginning_of_week(:monday) + 10h` to guarantee chart rendering.

- **`dateLabelMap` bridges ISO dates to x-axis labels:** `xAxis.getPixelForValue()` in Chart.js 4.x takes the label string (e.g. "Mon 9") not the raw data value. `dateLabelMap` translates `"2026-03-09"` → `"Mon 9"` by applying the same `toDayLabel()` function used to build chart labels.

- **`plugins: [markerPlugin]` as top-level Chart.js key:** Inline plugins must be passed in the `plugins` array alongside `type`/`data`/`options` in the `new Chart()` call — not via `Chart.register()`, which would apply them globally to all chart instances.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rewrote controller tests to avoid unavailable `assigns()` method**
- **Found during:** Task 1 verification
- **Issue:** `assigns()` in Rails integration tests requires the `rails-controller-testing` gem, which is not installed. Tests raised `NoMethodError`.
- **Fix:** Replaced three `assigns(:health_event_markers)` calls with equivalent assertions on rendered HTML attributes (`assert_select "canvas[data-chart-health-events-value]"` with block + `JSON.parse`) and response status checks.
- **Files modified:** `test/controllers/dashboard_controller_test.rb`
- **Verification:** All 4 new tests pass; only pre-existing `.dash-stats` failure remains.
- **Committed in:** `cd65460` (Task 1 commit)

**2. [Rule 1 - Bug] Tests create inline PeakFlowReading to guarantee chart section renders**
- **Found during:** Task 1 verification
- **Issue:** `canvas[data-chart-health-events-value]` test failed — canvas only renders inside `<% if @chart_data.any? %>` and fixture readings (`alice_green_reading` 2 days ago, `alice_yellow_reading` 1 day ago) fall before `beginning_of_week(:monday)` when today is Monday.
- **Fix:** Tests that assert canvas attributes now create a `PeakFlowReading` at `beginning_of_week(:monday) + 10h` and destroy it in the test body.
- **Files modified:** `test/controllers/dashboard_controller_test.rb`
- **Verification:** Canvas attribute tests pass reliably.
- **Committed in:** `cd65460` (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bug/correctness)
**Impact on plan:** Tests functionally equivalent to plan spec; no scope creep. Canvas assertion approach is more robust than `assigns()` for apps without `rails-controller-testing`.

## Issues Encountered

- The `test/system/medical_history_test.rb` chart marker test was already present in git commit `53d2ac6` (Phase 15-02 system test commit) due to stash timing during test verification; no duplicate commit was needed.
- Pre-existing test failures (dashboard `.dash-stats`, passwords, settings, adherence) confirmed pre-existing before this plan — 0 new failures introduced.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Health event markers visible on the dashboard 7-day peak flow chart
- Controller, view, and JS layers wired end-to-end; system test confirms data wiring
- Ready for Phase 15 completion or any further health events enhancements

---
*Phase: 15-health-events*
*Completed: 2026-03-09*

## Self-Check: PASSED

- FOUND: `app/controllers/dashboard_controller.rb` (contains `@health_event_markers`)
- FOUND: `app/views/dashboard/index.html.erb` (contains `data-chart-health-events-value`)
- FOUND: `app/javascript/controllers/chart_controller.js` (contains `healthEvents` + `afterDraw`)
- FOUND: `test/controllers/dashboard_controller_test.rb`
- FOUND: `test/system/medical_history_test.rb`
- FOUND: `.ariadna_planning/phases/15-health-events/15-03-SUMMARY.md`
- Commits verified: `cd65460`, `804474a`, `53d2ac6`
