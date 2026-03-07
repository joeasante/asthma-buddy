---
phase: 05-symptom-timeline
plan: 03
subsystem: ui
tags: [rails, turbo-streams, turbo-frames, capybara, system-tests, hotwire]

# Dependency graph
requires:
  - phase: 05-symptom-timeline
    provides: Turbo Frame timeline with trend_bar, filter_bar, timeline_list; SymptomLogsController with index/create actions; create.turbo_stream.erb with prepend + form reset

provides:
  - Live trend bar DOM update on create via turbo_stream.replace 'trend_bar'
  - Filter chip active CSS class updates on click (filter_bar inside timeline_content frame)
  - datetime input defaults to whole-minute value and accepts step-60 validation
  - Controller test: create turbo stream response includes trend_bar replace
  - System test assertion: filter-chip--active state after chip click

affects:
  - 06-peak-flow (severity color palette CSS and Turbo Frame patterns remain unchanged)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - turbo_stream.replace with id-wrapped partial for live DOM updates post-create
    - filter_bar inside turbo_frame renders active chip CSS without JS — standard Turbo frame re-render approach
    - Time.current.change(sec: 0) as clean-minute default for datetime_local_field with step: 60

key-files:
  created: []
  modified:
    - app/views/symptom_logs/index.html.erb
    - app/views/symptom_logs/create.turbo_stream.erb
    - app/controllers/symptom_logs_controller.rb
    - app/views/symptom_logs/_form.html.erb
    - test/controllers/symptom_logs_controller_test.rb
    - test/system/symptom_logging_test.rb

key-decisions:
  - "filter_bar moved INSIDE turbo_frame_tag 'timeline_content' — supersedes 05-01 decision that placed it outside; root cause of broken active-chip state was that the bar never re-rendered on chip click"
  - "@severity_counts computed from full user history (no date filter) in create action — trend bar reflects complete history matching fresh page load behavior"
  - "trend_bar wrapped in div#trend_bar in index.html.erb to provide stable DOM target for turbo_stream.replace"

# Metrics
duration: ~3min
completed: 2026-03-07
---

# Phase 5 Plan 03: Gap Closure Summary

**Three UAT-diagnosed gaps closed: live trend bar update on create via Turbo Stream replace targeting div#trend_bar, filter chip active-state visual fix by moving filter_bar inside the timeline_content frame, and datetime input step:60 with whole-minute default.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-07T15:09:19Z
- **Completed:** 2026-03-07T15:12:21Z
- **Tasks:** 3
- **Files modified:** 6 (3 view files, 1 controller, 2 test files)

## Accomplishments

- Added `div#trend_bar` wrapper in `index.html.erb` so `create.turbo_stream.erb` has a stable DOM target
- Added `turbo_stream.replace "trend_bar"` as first op in `create.turbo_stream.erb` — trend bar updates in the same render cycle as the new row appearing
- Computed `@severity_counts` from full user history in `create` action (no date filter, matching fresh page load)
- Moved `filter_bar` render from outside to inside `turbo_frame_tag "timeline_content"` — now re-renders with active chip CSS on every chip click
- Added `step: 60` to `datetime_local_field` — browser accepts whole-minute values without validation errors
- Changed index action `recorded_at` default to `Time.current.change(sec: 0)` — pre-filled value already at minute boundary
- Updated `create.turbo_stream.erb` form reset to use `Time.current.change(sec: 0)` for consistency
- Added controller test: create turbo stream response includes trend_bar replace
- Added system test assertion: `.filter-chip--active` text "7 days" after chip click

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix trend bar Turbo Stream update on create** - `0d4b96b` (feat)
2. **Task 2: Fix filter chip active state and datetime input step** - `352d589` (feat)
3. **Task 3: Full test suite green** - No new commit (verification only — all changes in tasks 1 and 2)

## Files Created/Modified

- `app/views/symptom_logs/index.html.erb` - Added div#trend_bar wrapper; moved filter_bar inside timeline_content frame
- `app/views/symptom_logs/create.turbo_stream.erb` - Added turbo_stream.replace 'trend_bar' as first op; fixed form reset recorded_at to use change(sec: 0)
- `app/controllers/symptom_logs_controller.rb` - Compute @severity_counts after save in create; change index recorded_at default to Time.current.change(sec: 0)
- `app/views/symptom_logs/_form.html.erb` - Added step: 60 to datetime_local_field
- `test/controllers/symptom_logs_controller_test.rb` - Added test: create turbo stream response includes trend_bar replace
- `test/system/symptom_logging_test.rb` - Added assertion: filter-chip--active text "7 days" after chip click

## Decisions Made

- `filter_bar` moved inside `turbo_frame_tag "timeline_content"` (supersedes 05-01 decision): Chip links use `data: { turbo_frame: "timeline_content" }` — when the bar is inside the frame these links navigate the frame, re-rendering the bar with the updated active chip. The original decision placed it outside, which meant the active-chip visual state never updated.
- `@severity_counts` in `create` uses full history (no date filter): The trend bar always reflects the user's complete history, matching the behavior on a fresh page load. Date filtering applies only to the timeline list.
- `div#trend_bar` wrapper approach chosen over adding id directly to trend_bar partial: Keeps the partial clean and makes the Turbo Stream target explicit in the consuming view.

## Deviations from Plan

None - plan executed exactly as written.

## Test Results

- **Before:** 100 tests, 304 assertions, 0 failures (end of 05-02)
- **After:** 101 tests, 307 assertions, 0 failures, 0 errors, 0 skips

## Self-Check: PASSED

Files verified:
- FOUND: app/views/symptom_logs/index.html.erb (contains id="trend_bar" and filter_bar inside timeline_content)
- FOUND: app/views/symptom_logs/create.turbo_stream.erb (contains turbo_stream.replace "trend_bar")
- FOUND: app/controllers/symptom_logs_controller.rb (contains severity_counts in create, change(sec: 0) in index)
- FOUND: app/views/symptom_logs/_form.html.erb (contains step: 60)
- FOUND: test/controllers/symptom_logs_controller_test.rb (contains trend_bar test)
- FOUND: test/system/symptom_logging_test.rb (contains filter-chip--active assertion)

Commits verified:
- FOUND: 0d4b96b (Task 1 — feat: add live trend bar Turbo Stream update on create)
- FOUND: 352d589 (Task 2 — feat: fix filter chip active state and datetime input step)

---
*Phase: 05-symptom-timeline*
*Completed: 2026-03-07*
