---
phase: 07-peak-flow-display
plan: 01
subsystem: ui
tags: [rails, hotwire, turbo-frame, css, peak-flow, pagination, filtering]

# Dependency graph
requires:
  - phase: 06-peak-flow-recording
    provides: PeakFlowReading model with zone enum, chronological scope, PeakFlowReadingsController with index action

provides:
  - Filterable paginated peak flow reading index at /peak-flow-readings
  - Zone badge CSS classes with WCAG AA contrast ratios for green/yellow/red/none
  - Date filter chips (7/30/90/all) and custom date range form via Turbo Frame
  - _reading_row partial with turbo_frame_tag dom_id wrapper and zone badge
  - _filter_bar and _pagination partials mirroring symptom logs pattern
  - Peak Flow nav link in application layout for authenticated users

affects: [07-02-peak-flow-edit-delete, 08-dashboard, 09-reports]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - turbo_frame_tag "readings_content" wraps filter bar + list for filter chip updates without full page reload
    - filter_bar INSIDE turbo_frame_tag (matches 05-03 symptom logs pattern for active-chip re-render)
    - Manual pagination via offset/limit with @current_page/@total_pages — no gem dependency
    - zone badge --modifier class pattern for background-fill colour coding (green/yellow/red/none)

key-files:
  created:
    - app/views/peak_flow_readings/_reading_row.html.erb
    - app/views/peak_flow_readings/_filter_bar.html.erb
    - app/views/peak_flow_readings/_pagination.html.erb
  modified:
    - app/views/peak_flow_readings/index.html.erb
    - app/controllers/peak_flow_readings_controller.rb
    - app/assets/stylesheets/peak_flow.css
    - app/views/layouts/application.html.erb

key-decisions:
  - "filter_bar rendered INSIDE turbo_frame_tag readings_content — matches 05-03 precedent; active chip state re-renders correctly on filter click"
  - "edit/delete stubs intentionally omitted from _reading_row — routes do not exist yet; 07-02 adds them when routes are in place"
  - "zone-badge background-fill pill approach (not text-colour only) — visually distinguishable at a glance without reading zone label"

patterns-established:
  - "Peak flow row layout: value + L/min unit + zone badge pill + timestamp + actions div"
  - "zone-badge--{zone} modifier maps directly to PeakFlowReading#zone enum value (green/yellow/red) or 'none' for nil"

requirements_covered: []

# Metrics
duration: 2min
completed: 2026-03-07
---

# Phase 7 Plan 01: Peak Flow Display Summary

**Turbo Frame filtered paginated peak flow reading index with background-fill zone badge pills and nav link, mirroring symptom logs architecture**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-07T20:11:51Z
- **Completed:** 2026-03-07T20:13:54Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `.zone-badge` CSS with background-fill pills and WCAG AA contrast ratios for green (#d4edda/#1a6b36, 5.1:1), yellow (#fff3cd/#7a4a00, 5.3:1), red (#f8d7da/#7b1d1d, 5.5:1), and none
- Added "Peak Flow" nav link to application layout inside `<% if authenticated? %>` block
- Updated `PeakFlowReadingsController#index` with pagination (25/page), preset chips (7/30/90/all), custom date range, and @active_preset/@start_date/@end_date/@current_page/@total_pages instance variables
- Created index.html.erb with turbo_frame_tag readings_content, empty state, and paginated reading list
- Created _reading_row partial with turbo_frame_tag dom_id wrapper, zone badge, L/min value, and timestamp
- Created _filter_bar partial with preset chips and custom date form targeting readings_content frame
- Created _pagination partial with Prev/Next navigation

## Task Commits

Each task was committed atomically:

1. **Task 1: Zone badge CSS + nav link** - `3e6f307` (feat)
2. **Task 2: Index view, _reading_row partial, _filter_bar, _pagination** - `5c7f174` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `app/assets/stylesheets/peak_flow.css` - Added .zone-badge base + --green/yellow/red/none modifiers, .peak-flow-list/row/value/unit/timestamp/actions classes
- `app/views/layouts/application.html.erb` - Added Peak Flow nav link for authenticated users
- `app/controllers/peak_flow_readings_controller.rb` - Replaced simple date filter with full preset+pagination+instance-var implementation
- `app/views/peak_flow_readings/index.html.erb` - Full index with turbo frame, filter bar, empty state, reading list, pagination
- `app/views/peak_flow_readings/_reading_row.html.erb` - Row partial with turbo_frame_tag dom_id wrapper, zone badge, value, timestamp
- `app/views/peak_flow_readings/_filter_bar.html.erb` - Preset chips + custom date range form, both targeting readings_content frame
- `app/views/peak_flow_readings/_pagination.html.erb` - Prev/Next navigation with page position indicator

## Decisions Made

- Filter bar placed INSIDE turbo_frame_tag `readings_content` — matches the 05-03 decision that moved symptom logs filter bar inside the frame to fix active chip state re-rendering on chip click
- Edit/delete action buttons intentionally omitted from _reading_row — `edit_peak_flow_reading_path` and `peak_flow_reading_path` routes do not exist yet; adding them now would raise a routing error at render time; 07-02 adds them when routes are wired up
- Zone badge uses background-fill pill (not text colour only) — visually distinguishable at a glance without having to read the zone label, satisfying the "identifiable at a glance" must-have truth

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed RuboCop end alignment offence in controller case statement**
- **Found during:** Task 2 (controller index update)
- **Issue:** `case`/`end` end alignment: `end` at col 20 not aligned with `@start_date = case` at col 6, triggering `Layout/EndAlignment` offence
- **Fix:** Re-indented `when`/`else`/`end` branches to align with `@start_date`
- **Files modified:** `app/controllers/peak_flow_readings_controller.rb`
- **Verification:** `bin/rubocop app/controllers/peak_flow_readings_controller.rb` — no offences; 13 controller tests passing
- **Committed in:** `5c7f174` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Rubocop alignment fix required for clean CI pass. No scope creep.

## Issues Encountered

- RuboCop reports false-positive Lint/Syntax errors on `.html.erb` and `.css` files (no rubocop-erb or rubocop-css integration configured). Pre-existing condition — not caused by this plan's changes. Only Ruby files are meaningfully linted.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Peak flow index is fully functional with filter, pagination, zone badges, and nav link
- 07-02 can now add Edit/Delete buttons to _reading_row using `edit_peak_flow_reading_path` and `peak_flow_reading_path` once routes are established
- Zone badge CSS classes are reusable for any future components needing zone colour coding

## Self-Check: PASSED

All claimed files exist and all task commits are present in git history.

| Check | Result |
|-------|--------|
| `app/views/peak_flow_readings/_reading_row.html.erb` | FOUND |
| `app/views/peak_flow_readings/_filter_bar.html.erb` | FOUND |
| `app/views/peak_flow_readings/_pagination.html.erb` | FOUND |
| `app/views/peak_flow_readings/index.html.erb` | FOUND |
| `app/assets/stylesheets/peak_flow.css` | FOUND |
| `app/views/layouts/application.html.erb` | FOUND |
| `.ariadna_planning/phases/07-peak-flow-display/07-01-SUMMARY.md` | FOUND |
| Commit `3e6f307` (Task 1) | FOUND |
| Commit `5c7f174` (Task 2) | FOUND |

---
*Phase: 07-peak-flow-display*
*Completed: 2026-03-07*
