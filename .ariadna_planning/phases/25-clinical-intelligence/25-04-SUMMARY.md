---
phase: 25-clinical-intelligence
plan: 04
subsystem: ui
tags: [dashboard, css, peak-flow, ux-polish, zone-colours]

requires:
  - phase: 25-clinical-intelligence
    provides: "Dashboard interpretation sentence, appointment summary page"
provides:
  - "Zone-coloured insight card replacing plain interpretation sentence"
  - "GP Summary button in dashboard page header"
  - "12-month personal best aging threshold"
affects: []

tech-stack:
  added: []
  patterns:
    - "dash-insight-card pattern: zone-coloured card with icon, left border, and background"

key-files:
  created: []
  modified:
    - app/views/dashboard/index.html.erb
    - app/assets/stylesheets/dashboard.css
    - app/views/peak_flow_readings/index.html.erb
    - test/controllers/dashboard_controller_test.rb

key-decisions:
  - "Used severity CSS variables for zone card colours to maintain design system consistency"
  - "Tightened PB aging threshold from 18 to 12 months per UAT feedback"

patterns-established:
  - "dash-insight-card: reusable zone-coloured card with icon + text for contextual status messages"

duration: 2min
completed: 2026-03-14
---

# Phase 25 Plan 04: Dashboard UX Polish Summary

**Zone-coloured insight card for weekly interpretation, GP Summary button in page header, and 12-month PB aging threshold**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-14T10:01:41Z
- **Completed:** 2026-03-14T10:03:23Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments
- Moved appointment summary link from bottom of This Week section to page-header-actions as a "GP Summary" button
- Replaced plain italic interpretation paragraph with a zone-coloured `.dash-insight-card` positioned before the stats grid
- Insight card displays zone-specific icons (checkmark/info/warning/pulse) and background colours (green/yellow/red/neutral)
- Tightened personal best aging threshold from 18 months to 12 months
- Updated two dashboard test selectors to match new `.dash-insight-card` class

## Task Commits

Each task was committed atomically:

1. **Task 1: Move appointment link, restyle interpretation, fix PB threshold, update tests** - `ec2a19b` (feat)

**Plan metadata:** [pending] (docs: complete plan)

## Files Created/Modified
- `app/views/dashboard/index.html.erb` - Added page-header-actions with GP Summary button; replaced .dash-interpretation with .dash-insight-card before stats grid; removed dash-appt-link
- `app/assets/stylesheets/dashboard.css` - Replaced .dash-interpretation styles with .dash-insight-card and zone variants (green/yellow/red/none)
- `app/views/peak_flow_readings/index.html.erb` - Changed 18.months.ago to 12.months.ago for PB aging notice
- `test/controllers/dashboard_controller_test.rb` - Updated two assert_select calls from .dash-interpretation to .dash-insight-card

## Decisions Made
- Used existing severity CSS variables (--severity-mild-bg, --severity-moderate-bg, --severity-severe-bg) for zone card backgrounds to maintain design system consistency
- Tightened PB aging from 18 to 12 months per UAT feedback -- 18 months was too generous for detecting lung function changes

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All three gap-closure plans (25-03, 25-04) complete
- Phase 25 clinical intelligence features fully polished

---
*Phase: 25-clinical-intelligence*
*Completed: 2026-03-14*
