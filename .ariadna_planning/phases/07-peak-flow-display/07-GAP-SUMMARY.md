---
phase: 07-peak-flow-display
plan: GAP
subsystem: ui

tags: [rails, css, custom-properties, layout, navigation, flash, forms]

# Dependency graph
requires:
  - phase: 07-peak-flow-display
    provides: Layout HTML with nav classes, flash classes, and structural elements in application.html.erb
  - phase: 05-symptom-timeline
    provides: symptom_timeline.css defining severity CSS custom properties (re-declared globally here)
  - phase: 06-peak-flow-recording
    provides: peak_flow.css consuming --severity-mild/moderate/severe; confirm_dialog.css consuming --severity-severe

provides:
  - Global CSS custom properties on :root (severity palette, brand colours, neutrals, spacing, radii, layout)
  - Box-sizing reset
  - Base typography (body, h1-h3, p, a)
  - Page layout (sticky header, flex-column body, contained main, footer)
  - Navigation classes (.nav-brand, .nav-auth, .nav-link, .nav-user-email, .btn-sign-out)
  - Flash message classes (#flash-messages, .flash, .flash--notice, .flash--alert)
  - Base form/input styles with focus rings
  - Global availability of --severity-* custom properties so confirm_dialog.css resolves them regardless of load order

affects:
  - 08-trend-analysis
  - 09-accessibility

# Tech tracking
tech-stack:
  added: []
  patterns:
    - CSS custom properties on :root as single source of truth for design tokens
    - Severity/zone colour palette declared globally so feature stylesheets can consume without coupling to each other
    - Sticky header with z-index 100 above all page content
    - Flex-column body for footer-to-bottom layout

key-files:
  created: []
  modified:
    - app/assets/stylesheets/application.css

key-decisions:
  - "--severity-* custom properties declared on :root in application.css even though symptom_timeline.css also declares them — ensures confirm_dialog.css resolves them regardless of stylesheet load order; re-declaration is harmless"
  - "Did not redeclare .btn-primary (peak_flow.css), .btn-confirm-cancel/.btn-confirm-delete (confirm_dialog.css), or any feature-specific classes — each file owns its own classes"
  - "System-ui font stack chosen for native look across platforms without loading a web font"

patterns-established:
  - "Pattern 1: CSS custom properties live on :root in application.css — feature CSS files consume via var() without re-declaring"
  - "Pattern 2: Nav and flash class names in application.css must exactly match the class= attributes in application.html.erb"

# Metrics
duration: 3min
completed: 2026-03-07
---

# Phase 7 GAP: Peak Flow Display — Global Base Stylesheet Summary

**Global application.css stylesheet with CSS custom properties, reset, typography, sticky-header page layout, nav/flash classes, and base form styles — making every page visually styled out of the box.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-07T00:00:00Z
- **Completed:** 2026-03-07T00:03:00Z
- **Tasks:** 1 of 1
- **Files modified:** 1

## Accomplishments

- Replaced empty `application.css` with a 287-line complete base stylesheet
- All nav classes referenced in `application.html.erb` now have matching CSS rules
- CSS custom properties for severity palette declared globally so `confirm_dialog.css` resolves `--severity-severe` regardless of stylesheet load order
- Base form inputs now have consistent block layout with brand-coloured focus rings
- 177 tests, 501 assertions — all pass; no regressions introduced

## Task Commits

Each task was committed atomically:

1. **Task 1: Write global base stylesheet into application.css** - `2e6d5c2` (feat)

**Plan metadata:** (created below with docs commit)

## Files Created/Modified

- `app/assets/stylesheets/application.css` — Complete global base stylesheet: :root custom properties, box-sizing reset, base typography, page layout, nav classes, flash message classes, base form/button styles

## Decisions Made

- `--severity-*` custom properties placed on `:root` in `application.css` even though `symptom_timeline.css` also declares them. This ensures `confirm_dialog.css` (which uses `var(--severity-severe, #c0392b)` with a fallback) reliably resolves the variable no matter which stylesheet loads first. Re-declaration with identical values is harmless.
- `.btn-primary`, `.btn-confirm-cancel`, `.btn-confirm-delete`, and all feature-specific classes deliberately omitted — each feature stylesheet owns its own classes. Only global/layout concerns live in `application.css`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 8 (Trend Analysis) will inherit the full CSS custom property palette from `:root` — no additional global styles needed
- All severity/zone colors available globally via `var(--severity-mild)`, `var(--severity-moderate)`, `var(--severity-severe)` and their `-bg` variants
- Navigation, flash, layout, and form base styles are stable; feature stylesheets continue to work without modification

---
*Phase: 07-peak-flow-display*
*Completed: 2026-03-07*

## Self-Check: PASSED

- FOUND: `app/assets/stylesheets/application.css`
- FOUND: `07-GAP-SUMMARY.md`
- FOUND: commit `2e6d5c2` (feat(07-GAP): write global base stylesheet into application.css)
