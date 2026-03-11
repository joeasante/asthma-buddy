---
phase: 19-notifications
plan: 02
subsystem: ui
tags: [rails, turbo-streams, stimulus, notifications, css]

# Dependency graph
requires:
  - phase: 19-01
    provides: Notification model with unread scope, newest_first scope, enum notification_type, Current.user.notifications association
provides:
  - NotificationsController with index, mark_read, mark_all_read actions scoped to Current.user
  - /notifications feed with empty state and unread styling
  - Turbo Stream mark_read replacing single row + updating nav bell badge
  - Turbo Stream mark_all_read replacing all rows + zeroing badge
  - layouts/_nav_bell.html.erb partial for Turbo Stream replacement
  - notifications.css with feed styles, unread indicators, bell badge ::after
  - relative_time_controller.js Stimulus controller (updates every 60s)
  - Bell icon in desktop header with data-unread-count badge
  - Notifications/Alerts tab in bottom nav (replacing Medications tab)
affects: [19-03, future nav changes]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Turbo Stream nav badge update: replace id='nav-bell' partial on any mark-read action"
    - "data-unread-count + has-unread-badge CSS ::after pattern for badge dot without JS"
    - "turbo_frame_tag dom_id(notification) on each row enables individual row replacement"
    - "resolve_notification_path rescues ActiveRecord::RecordNotFound for deleted notifiables"

key-files:
  created:
    - app/controllers/notifications_controller.rb
    - app/views/notifications/index.html.erb
    - app/views/notifications/_notification.html.erb
    - app/views/notifications/mark_read.turbo_stream.erb
    - app/views/notifications/mark_all_read.turbo_stream.erb
    - app/views/layouts/_nav_bell.html.erb
    - app/assets/stylesheets/notifications.css
    - app/javascript/controllers/relative_time_controller.js
  modified:
    - config/routes.rb
    - app/views/layouts/application.html.erb
    - app/views/layouts/_bottom_nav.html.erb

key-decisions:
  - "_nav_bell partial extracted so Turbo Stream can replace id='nav-bell' after mark_read/mark_all_read without a full page reload"
  - "data-unread-count integer attribute on link elements; CSS .has-unread-badge[data-unread-count]:not([data-unread-count='0'])::after renders dot — no JS badge counter needed"
  - "Bottom nav Medications tab replaced with Notifications (Alerts) tab; Medications remains accessible in desktop header"
  - "resolve_notification_path rescues RecordNotFound per-case and calls update_columns(read:true) before falling back to safe path"
  - "relative_time_controller.js uses pure JS (no external library), 60s interval, simple threshold-based format()"

patterns-established:
  - "Nav badge update pattern: render partial with id matching Turbo Stream replace target; data attribute drives CSS ::after badge"
  - "Notification row isolation: turbo_frame_tag dom_id(notification) per row so individual mark_read only replaces that frame"

# Metrics
duration: ~3min
completed: 2026-03-11
---

# Plan 19-02 Summary: Notifications UI

**Full notifications feed with Turbo Stream mark-read, CSS unread badge, relative_time Stimulus controller, bell icon in desktop nav, and Alerts tab in bottom nav replacing Medications.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-11T10:19:08Z
- **Completed:** 2026-03-11T10:21:37Z
- **Tasks:** 2
- **Files created:** 8
- **Files modified:** 3

## Accomplishments

- NotificationsController with index, mark_read (PATCH), mark_all_read (POST) all scoped to `Current.user`; broken notifiable targets rescued with safe fallback path and auto-mark-read
- Turbo Stream flows: mark_read replaces individual notification row via `turbo_frame_tag dom_id(notification)` and replaces `nav-bell` partial to update badge count; mark_all_read does same for all rows
- CSS `::after` badge driven entirely by `data-unread-count` integer attribute and `.has-unread-badge` class — no JS required for badge rendering; works on both desktop bell and mobile bottom nav tab

## Task Commits

1. **Task 1: NotificationsController, routes, and Turbo Stream views** - `4b4ca05` (feat)
2. **Task 2: CSS, relative_time Stimulus controller, nav bell, and bottom nav Alerts tab** - `8be0053` (feat)

## Files Created

| File | Purpose |
|------|---------|
| `app/controllers/notifications_controller.rb` | index, mark_read, mark_all_read; scoped to Current.user; RecordNotFound rescue |
| `app/views/notifications/index.html.erb` | Feed: page-header, mark-all-read button, notification list, empty state |
| `app/views/notifications/_notification.html.erb` | Single row: turbo_frame_tag, unread dot, type SVG icon, bold body, relative timestamp |
| `app/views/notifications/mark_read.turbo_stream.erb` | Replaces single notification row + nav-bell partial |
| `app/views/notifications/mark_all_read.turbo_stream.erb` | Replaces all rows + nav-bell with count 0 |
| `app/views/layouts/_nav_bell.html.erb` | Bell icon link with id="nav-bell", has-unread-badge, data-unread-count |
| `app/assets/stylesheets/notifications.css` | Feed styles, unread row, type icon colours, bell badge ::after, empty state |
| `app/javascript/controllers/relative_time_controller.js` | Stimulus controller: pure JS relative time, updates every 60s |

## Files Modified

| File | Change |
|------|--------|
| `config/routes.rb` | Added notifications resource (index, mark_read member PATCH, mark_all_read collection POST) |
| `app/views/layouts/application.html.erb` | Added notifications.css to authenticated block; added nav_bell partial before user dropdown |
| `app/views/layouts/_bottom_nav.html.erb` | Replaced Medications tab with Notifications/Alerts tab (bell SVG, has-unread-badge) |

## Decisions Made

1. **_nav_bell extracted as a layout partial**: Turbo Stream `replace "nav-bell"` works only when the element being replaced can be rendered in isolation. Extracting `_nav_bell.html.erb` allows both the initial render (in application layout) and Turbo Stream updates (in mark_read/mark_all_read stream views) to use the same partial, ensuring consistent HTML.

2. **data-unread-count CSS badge strategy**: Rather than injecting badge count text via JS, the `data-unread-count` integer attribute is set on the link element. CSS `.has-unread-badge[data-unread-count]:not([data-unread-count="0"])::after` renders a red dot when count > 0. This requires no JS logic for badge rendering, works for both desktop bell and mobile bottom nav via separate CSS rules, and updates automatically when Turbo Stream replaces the element.

3. **Bottom nav Medications tab replaced**: Plan specified this replacement. Medications remains accessible in the desktop header nav. The mobile Alerts tab uses the same bell SVG as the desktop bell for visual consistency.

4. **resolve_notification_path with per-type rescue**: Each notification_type case has its own `begin/rescue` block. This makes the fallback explicit per type — future notification_type additions can declare their own fallback path without a catch-all masking errors.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## Test Results

- Tests run: 451
- Failures: 0
- Errors: 0
- Skips: 0
- Regressions: 0

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Notifications UI fully wired to the data layer from 19-01
- Bell badge and Alerts tab ready for Phase 19-03 (controller tests and system tests)
- mark_read and mark_all_read Turbo Stream flows complete and ready for test coverage

## Self-Check: PASSED

All 8 created files verified present. Both task commits (4b4ca05, 8be0053) verified in git log. 451 tests passing, 0 regressions.

---
*Phase: 19-notifications*
*Completed: 2026-03-11*
