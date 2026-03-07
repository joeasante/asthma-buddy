---
phase: 06-peak-flow-recording
plan: 05
subsystem: ui
tags: [rails, turbo-stream, hotwire, turbo-frame, html-safe, css-custom-properties]

# Dependency graph
requires:
  - phase: 06-peak-flow-recording
    provides: peak flow create controller with zone_flash_message, create.turbo_stream.erb, _form partial, and peak_flow.css

provides:
  - Blank value field blocked at browser via HTML5 required attribute on number_field
  - Flash messages replace rather than accumulate via turbo_stream.replace targeting stable id="flash-messages" div
  - Form resets cleanly after each successful submission (value clears, datetime resets) via turbo_frame_tag wrapper in stream response
  - Zone name in flash rendered in zone colour (green/amber/red) via html_safe span with zone-label CSS classes

affects:
  - future phases that modify application layout flash area
  - system tests that assert flash message content or presence

# Tech tracking
tech-stack:
  added: []
  patterns:
    - turbo_stream.replace targeting a stable wrapper div (id="flash-messages") avoids flash accumulation — preferred over prepend to main content
    - turbo_stream.replace must supply outer turbo_frame_tag wrapper when replacing a frame element — frame disappears from DOM otherwise
    - html_safe + raw() for controller-generated HTML in Turbo Stream templates — marked at source, rendered unescaped at template
    - CSS custom properties (--severity-mild/moderate/severe) shared across peak_flow.css and symptom_timeline.css for zone colours

key-files:
  created: []
  modified:
    - app/views/peak_flow_readings/_form.html.erb
    - app/views/peak_flow_readings/create.turbo_stream.erb
    - app/views/layouts/application.html.erb
    - app/controllers/peak_flow_readings_controller.rb
    - app/assets/stylesheets/peak_flow.css

key-decisions:
  - "id=\"flash-messages\" div always rendered in layout (even when no flash) so Turbo Stream replace target always exists in DOM"
  - "turbo_stream.replace 'flash-messages' supersedes turbo_stream.prepend 'main-content' from 06-03 — replace is correct for non-accumulating flash"
  - "turbo_frame_tag wrapper supplied in create.turbo_stream.erb not in _form partial — frame lifecycle managed at stream layer"
  - "html_safe marked on zone_flash_message return value, raw() used in template — consistent with Rails convention for controller-generated HTML fragments"

patterns-established:
  - "Always render the flash container div (id=flash-messages) unconditionally in layout — empty div is cheaper than missing Turbo Stream target"
  - "Turbo Stream replace of a turbo-frame element must re-supply the frame tag — partial rendering alone loses the frame element"

requirements_covered: []

# Metrics
duration: 5min
completed: 2026-03-07
---

# Phase 6 Plan 05: UAT Gap Closure — Blank Validation, Flash Replace, Zone Colour Summary

**Three UAT gaps closed: blank submit blocked natively via required attribute, flash messages replace via stable id="flash-messages" div targeted by Turbo Stream, and zone names render in coloured spans using --severity-* CSS custom properties.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-07T17:34:00Z
- **Completed:** 2026-03-07T17:39:49Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `required: true` to `number_field :value` in `_form.html.erb` — blank submits blocked by browser native validation tooltip, no server round-trip
- Wrapped layout flash notices in `<div id="flash-messages">` so Turbo Stream has a stable replace target present on every page load
- Rewrote `create.turbo_stream.erb`: form replace now wraps partial in `turbo_frame_tag` so the frame element persists in the DOM across successive submissions
- Switched flash from `turbo_stream.prepend "main-content"` to `turbo_stream.replace "flash-messages"` — each submission shows exactly one flash, not a growing stack
- Updated `zone_flash_message` in controller to return `html_safe` string containing a `<span class="zone-label zone-label--{zone}">` wrapping the zone name and percentage
- Added `.zone-label`, `.zone-label--green`, `.zone-label--yellow`, `.zone-label--red` to `peak_flow.css` using `var(--severity-mild/moderate/severe)` custom properties

## Task Commits

Each task was committed atomically:

1. **Task 1: Add required field, fix Turbo Stream form reset and flash replace** - `37cf9d9` (feat)
2. **Task 2: Coloured zone name in flash via html_safe span and zone CSS classes** - `5764d02` (feat)

**Plan metadata:** (docs commit to follow)

## Files Created/Modified

- `app/views/peak_flow_readings/_form.html.erb` — Added `required: true` to number_field :value
- `app/views/peak_flow_readings/create.turbo_stream.erb` — Full rewrite: turbo_frame_tag wrapper, replace flash-messages, raw() for html_safe message
- `app/views/layouts/application.html.erb` — Flash notices wrapped in `<div id="flash-messages">` for stable Turbo Stream target
- `app/controllers/peak_flow_readings_controller.rb` — zone_flash_message returns html_safe string with coloured span; plain-text fallback unchanged
- `app/assets/stylesheets/peak_flow.css` — Zone label colour classes using --severity-* custom properties

## Decisions Made

- `id="flash-messages"` div always rendered in layout unconditionally (even when no flash present) so Turbo Stream replace target always exists in the DOM — avoids "element not found" on first submission after page load
- `turbo_stream.replace "flash-messages"` supersedes `turbo_stream.prepend "main-content"` decision from 06-03 — replace is the correct primitive for non-accumulating flash messages
- The `turbo_frame_tag` wrapper is supplied in `create.turbo_stream.erb`, not inside `_form.html.erb` — the partial renders the inner form content only; the frame lifecycle is managed at the stream layer
- `html_safe` marked on zone_flash_message return value in the controller, `raw()` used in the template — consistent Rails convention for controller-generated HTML fragments

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None — all 152 tests passed with 0 failures after each change.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All 8 UAT scenarios for Phase 6 peak flow recording are now addressed
- Phase 6 is fully ship-ready: blank validation, clean form reset, non-accumulating flash, coloured zone names
- Phase 7 (or whichever phase follows) can build on the established flash/Turbo pattern: always use `id="flash-messages"` wrapper and `turbo_stream.replace` for flash updates

## Self-Check: PASSED

All 6 files confirmed present. Both task commits (37cf9d9, 5764d02) confirmed in git log.

---
*Phase: 06-peak-flow-recording*
*Completed: 2026-03-07*
