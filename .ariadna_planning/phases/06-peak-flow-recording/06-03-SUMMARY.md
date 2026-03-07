---
phase: 06-peak-flow-recording
plan: 03
subsystem: ui
tags: [rails, turbo, turbo-stream, hotwire, controller, views, css, peak-flow]

# Dependency graph
requires:
  - phase: 06-01
    provides: PeakFlowReading model with zone enum, before_save assign_zone, personal_best_at_reading_time; PersonalBestRecord with current_for
  - phase: 06-02
    provides: SettingsController, settings_path for banner link
affects:
  - 06-04+ (system tests for this form, future peak flow history views)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - turbo_frame_tag wraps form partial for Turbo Stream replace targeting by DOM id
    - create.turbo_stream.erb resets form with fresh record + prepends flash to main-content
    - Conditional banner (has_personal_best) passed as local to form partial
    - zone_flash_message private method computes label and percentage post-save

key-files:
  created:
    - app/controllers/peak_flow_readings_controller.rb
    - app/views/peak_flow_readings/new.html.erb
    - app/views/peak_flow_readings/_form.html.erb
    - app/views/peak_flow_readings/create.turbo_stream.erb
    - app/assets/stylesheets/peak_flow.css
  modified:
    - config/routes.rb

key-decisions:
  - "turbo_stream.prepend 'main-content' used for flash in create.turbo_stream.erb — layout <main id='main-content'> is skip-link target (established 01-02), no separate flash container needed"
  - "zone_flash_message reads personal_best_at_reading_time from the saved record — zone is already assigned by before_save, so reading.zone and pb are always consistent"
  - "has_personal_best passed as ivar from controller and local to form partial — consistent with 06-02 settings pattern"

patterns-established:
  - "peak_flow_reading_form: turbo_frame DOM id for form replace on error (422) and reset on success"
  - "zone_flash_message: 'Reading saved — Green Zone (83% of personal best).' / 'Reading saved — set your personal best to see your zone.'"

# Metrics
duration: 1min
completed: 2026-03-07
---

# Phase 6 Plan 03: Peak Flow Entry Form Summary

**PeakFlowReadingsController with new and create actions, large-numeric entry form with conditional personal-best banner, Turbo Stream create response with zone-aware flash, and peak_flow.css.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-07T16:29:45Z
- **Completed:** 2026-03-07T16:30:54Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- PeakFlowReadingsController: new and create actions, multi-user isolation via Current.user scoping, zone_flash_message private method computing zone label and percentage
- Entry form at /peak_flow_readings/new: large 2rem centered numeric input with L/min unit label, datetime field, error display, conditional yellow banner when no personal best
- Turbo Stream create response: replaces form with fresh record, prepends zone-aware flash to main-content
- peak_flow.css: large numeric input styles (no spinners), L/min unit, banner amber styling
- Full test suite: 123 tests, 343 assertions, 0 failures

## Task Commits

Each task was committed atomically:

1. **Task 1: Routes and PeakFlowReadingsController (new + create)** - `92cb07a` (feat)
2. **Task 2: Entry form views, Turbo Stream response, and CSS** - `21be8aa` (feat)

## Files Created/Modified

- `config/routes.rb` - Added resources :peak_flow_readings, only: [:new, :create]
- `app/controllers/peak_flow_readings_controller.rb` - new and create actions, zone_flash_message helper
- `app/views/peak_flow_readings/new.html.erb` - Page with turbo_frame_tag "peak_flow_reading_form" wrapping the form partial
- `app/views/peak_flow_readings/_form.html.erb` - Conditional banner, large numeric input, L/min unit, datetime, error list
- `app/views/peak_flow_readings/create.turbo_stream.erb` - Replace form with fresh record, prepend zone flash to main-content
- `app/assets/stylesheets/peak_flow.css` - Large centered numeric input (2rem, no spinners), unit label, amber banner

## Decisions Made

- `turbo_stream.prepend "main-content"` used for the zone-aware flash — the layout `<main id="main-content">` is already established as the skip-link target (01-02 decision), making it a stable DOM anchor without needing a separate flash container.
- `zone_flash_message` reads `personal_best_at_reading_time` from the saved record after `before_save :assign_zone` has run, ensuring zone and personal best percentage are always consistent.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Entry form functional at /peak_flow_readings/new — Phase 6 plan 04 (system tests for this form) can proceed.
- Both Turbo Stream paths (success + error) implemented and verified by existing test suite.
- No blockers.

---
*Phase: 06-peak-flow-recording*
*Completed: 2026-03-07*

## Self-Check: PASSED

All claimed files verified on disk. Both task commits confirmed in git log.

| Check | Result |
|-------|--------|
| config/routes.rb | FOUND |
| app/controllers/peak_flow_readings_controller.rb | FOUND |
| app/views/peak_flow_readings/new.html.erb | FOUND |
| app/views/peak_flow_readings/_form.html.erb | FOUND |
| app/views/peak_flow_readings/create.turbo_stream.erb | FOUND |
| app/assets/stylesheets/peak_flow.css | FOUND |
| Commit 92cb07a | FOUND |
| Commit 21be8aa | FOUND |
