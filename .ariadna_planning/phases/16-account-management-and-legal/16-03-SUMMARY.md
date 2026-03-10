---
phase: 16-account-management-and-legal
plan: 03
subsystem: ui
tags: [rails, stimulus, hotwire, turbo, session, cookie-notice, accessibility, eprivacy]

# Dependency graph
requires:
  - phase: 16-account-management-and-legal
    provides: privacy_path and terms_path routes used in cookie notice banner
provides:
  - Dismissible session cookie notice banner shown once per session (ePrivacy LEGAL-03)
  - CookieNoticesController#dismiss sets session[:cookie_notice_shown]=true
  - cookie_notice Stimulus controller with CSS transition dismiss animation
affects:
  - ApplicationController (before_action on every request)
  - All layout pages (banner rendered globally)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Session flag pattern for show-once UI: session[:key] guards @instance_var set in before_action"
    - "button_to + head :no_content for Stimulus-driven dismiss: no redirect, no Turbo Stream needed"
    - "CSS transition + transitionend event for animated element removal (no setTimeout)"

key-files:
  created:
    - app/controllers/cookie_notices_controller.rb
    - app/views/layouts/_cookie_notice.html.erb
    - app/javascript/controllers/cookie_notice_controller.js
    - app/assets/stylesheets/cookie_notice.css
    - test/system/cookie_notice_test.rb
  modified:
    - app/controllers/application_controller.rb
    - app/views/layouts/application.html.erb
    - config/routes.rb

key-decisions:
  - "head :no_content (204) for dismiss response — Stimulus handles client-side hide, no redirect/Turbo Stream needed"
  - "eagerLoadControllersFrom auto-registers Stimulus controllers — no manual index.js entry required"
  - "cookie_notice.css loaded unconditionally (outside authenticated? block) — banner shown to unauthenticated visitors too"
  - "Third system test (browser cookie API approach) omitted — plan noted it was flaky; two tests cover the key behaviours"
  - "bottom: 52px mobile offset keeps banner above the bottom nav"

patterns-established:
  - "Show-once session banner: before_action sets @show_cookie_notice = !session[:key]; controller action sets session[:key]"

requirements_covered:
  - id: "LEGAL-03"
    description: "Informational ePrivacy cookie notice for essential session cookies"
    evidence: "app/controllers/cookie_notices_controller.rb, app/views/layouts/_cookie_notice.html.erb"

# Metrics
duration: 5min
completed: 2026-03-10
---

# Phase 16 Plan 03: Cookie Notice Banner Summary

**Dismissible session cookie notice banner using Stimulus + 204 response pattern, shown once per session for ePrivacy LEGAL-03 compliance**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-03-10T00:00:00Z
- **Completed:** 2026-03-10T00:05:00Z
- **Tasks:** 2
- **Files modified:** 8 (3 modified, 5 created)

## Accomplishments
- ApplicationController `set_cookie_notice_flag` before_action sets `@show_cookie_notice = !session[:cookie_notice_shown]` on every request
- `CookieNoticesController#dismiss` sets `session[:cookie_notice_shown]=true` and returns `head :no_content` (204)
- `_cookie_notice.html.erb` partial with `role="region"`, `aria-label="Cookie notice"`, `button_to` dismiss button with `aria-label`
- `cookie_notice_controller.js` Stimulus controller: `dismiss()` adds CSS class then removes element on `transitionend`
- `cookie_notice.css` positions banner fixed bottom, slides out via `opacity`/`translateY`, offsets above mobile bottom nav at `bottom: 52px`
- System tests: shows on first visit; dismissed and does not reappear after dismiss (2/2 pass)
- Full test suite: 374 passing, 0 regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: ApplicationController, CookieNoticesController, route, banner partial, Stimulus controller, CSS** - `ba5a91d` (feat)
2. **Task 2: Wire banner into layout and write system tests** - `6e0592e` (feat)

## Files Created/Modified
- `app/controllers/application_controller.rb` - Added `set_cookie_notice_flag` before_action and private method
- `app/controllers/cookie_notices_controller.rb` - New: dismiss action sets session flag, returns 204
- `config/routes.rb` - Added `POST /cookie-notice/dismiss` as `cookie_notice_dismiss`
- `app/views/layouts/_cookie_notice.html.erb` - New: banner partial with accessible markup and Stimulus wiring
- `app/javascript/controllers/cookie_notice_controller.js` - New: Stimulus dismiss controller with CSS transition + element removal
- `app/assets/stylesheets/cookie_notice.css` - New: fixed-bottom banner styles, dismissed state transition, mobile offset
- `app/views/layouts/application.html.erb` - Added `stylesheet_link_tag "cookie_notice"` and `render "layouts/cookie_notice" if @show_cookie_notice`
- `test/system/cookie_notice_test.rb` - New: 2 system tests (first visit shows, dismiss hides and does not reappear)

## Decisions Made
- `head :no_content` (204) for dismiss response: Stimulus handles client-side removal, no redirect or Turbo Stream required
- `eagerLoadControllersFrom` in `index.js` auto-registers all `*_controller.js` files — no manual entry in `index.js` needed
- Cookie notice CSS loaded unconditionally (outside `authenticated?` block) — the banner can appear to unauthenticated visitors
- Third system test with browser cookie API omitted as plan recommended simplification to two reliable tests
- `bottom: 52px` on mobile keeps banner visible above the bottom navigation bar

## Deviations from Plan

None - plan executed exactly as written (third system test intentionally simplified per plan guidance).

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Cookie notice infrastructure complete; banner is shown to all visitors once per session
- `session[:cookie_notice_shown]` persists for the duration of the browser session
- Ready for Phase 16-04 (if applicable) or subsequent phases

---
*Phase: 16-account-management-and-legal*
*Completed: 2026-03-10*

## Self-Check: PASSED

All files verified present, all commits confirmed in git history.
