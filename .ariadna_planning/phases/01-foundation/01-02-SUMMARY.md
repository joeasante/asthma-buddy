---
phase: 01-foundation
plan: 02
subsystem: ui
tags: [rails, routes, erb, html5, accessibility, wcag]

# Dependency graph
requires: []
provides:
  - Root route wired to HomeController#index (GET / => 200)
  - HomeController with index action
  - Homepage view placeholder
  - Application layout with semantic HTML5 structure (header, nav, main, footer)
  - Flash message rendering (notice/alert) in layout
  - ARIA landmark roles (banner, navigation, main, contentinfo)
affects: [02-auth, 05-navigation, 09-accessibility]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Semantic HTML5 structure with ARIA landmark roles established in base layout
    - Flash messages rendered in layout using notice.present?/alert.present? checks
    - content_for :title pattern for per-view page titles

key-files:
  created:
    - app/controllers/home_controller.rb
    - app/views/home/index.html.erb
  modified:
    - config/routes.rb
    - app/views/layouts/application.html.erb

key-decisions:
  - "Use lang='en' on <html> element for WCAG 2.2 AA compliance — cheap to add now, required in Phase 9"
  - "ARIA landmark roles on all structural elements for screen reader support from the start"
  - "id='main-content' on <main> for future skip-link target (Phase 9)"
  - "Nav comment placeholder marks Phase 2 auth link insertion point"
  - "PWA manifest commented out — Phase 9 enables when route is configured"

patterns-established:
  - "Application layout: all views inherit header/nav/main/footer structure"
  - "Flash messages: rendered in layout using role=status (notice) and role=alert (alert)"
  - "Page titles: set per-view via content_for :title, fall back to 'Asthma Buddy'"

requirements_covered: []

# Metrics
duration: 5min
completed: 2026-03-06
---

# Phase 1 Plan 02: Root Route, HomeController, and Application Layout Shell Summary

**Root route wired to HomeController#index with semantic HTML5 layout shell providing header/nav/main/flash/footer structure for all subsequent phases**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-06T00:00:00Z
- **Completed:** 2026-03-06T00:05:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Root route `GET /` now returns 200 via HomeController#index
- HomeController created with empty index action
- Homepage view placeholder with page title via `content_for :title`
- Application layout updated with full semantic HTML5 structure
- ARIA landmark roles (banner, navigation, main, contentinfo) present from the start
- Flash messages (notice/alert) render in layout with appropriate ARIA roles
- Phase 2 auth link insertion point marked with comment in nav

## Task Commits

Each task was committed atomically:

1. **Task 1: Add root route and HomeController** - `9725cf8` (feat)
2. **Task 2: Update application layout with nav shell and flash messages** - `9c74f14` (feat)

## Files Created/Modified
- `config/routes.rb` - Added `root "home#index"` keeping health check intact
- `app/controllers/home_controller.rb` - Minimal HomeController with index action
- `app/views/home/index.html.erb` - Homepage placeholder with title and descriptive text
- `app/views/layouts/application.html.erb` - Full semantic HTML5 layout with header, nav, main (flash), footer

## Decisions Made
- Added `lang="en"` to `<html>` for WCAG 2.2 AA compliance — cheap to add at layout creation, required by Phase 9
- Used `role="status"` on notice flash and `role="alert"` on alert flash for screen reader announcement semantics
- Added `id="main-content"` to `<main>` as skip-link target (skip link to be added in Phase 9)
- Commented out PWA manifest tag — Phase 9 enables it when the manifest route is configured
- Added nav comment explicitly marking where Phase 2 inserts sign-in/sign-out links

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Root path returns 200, layout shell is in place
- Phase 2 can add authentication links directly in the marked nav comment location
- Phase 5 can add navigation links to the same nav element
- Phase 9 can add skip-link targeting `#main-content` and enable PWA manifest

---
*Phase: 01-foundation*
*Completed: 2026-03-06*
