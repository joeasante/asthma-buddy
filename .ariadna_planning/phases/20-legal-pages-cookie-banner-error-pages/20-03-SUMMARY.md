---
phase: 20-legal-pages-cookie-banner-error-pages
plan: 03
subsystem: ui
tags: [rails, error-pages, exceptions-app, middleware, html, css]

requires:
  - phase: 20-01-legal-pages
    provides: legal.css and application layout stylesheet loading pattern

provides:
  - Branded 404 error page via ErrorsController#not_found
  - Branded 500 error page via ErrorsController#internal_server_error
  - errors.css with CSS custom properties for error page layout
  - config.exceptions_app = self.routes wiring in application.rb
  - public/maintenance.html — standalone self-contained maintenance page
  - 5 controller tests covering status codes, content, and unauthenticated access
affects:
  - Deployment (maintenance.html served directly without Rails at nginx/CDN level)
  - Future error handling (exceptions_app now routes all errors through ErrorsController)

tech-stack:
  added: []
  patterns:
    - "exceptions_app pattern: config.exceptions_app = self.routes routes Rails exceptions through our controller"
    - "error page layout: absolute .error-code behind z-index: 1 .error-content using CSS custom properties"
    - "standalone HTML: inline <style>, Google Fonts CDN, hex colour fallbacks for non-Rails pages"

key-files:
  created:
    - app/controllers/errors_controller.rb
    - app/views/errors/not_found.html.erb
    - app/views/errors/internal_server_error.html.erb
    - app/assets/stylesheets/errors.css
    - public/maintenance.html
    - test/controllers/errors_controller_test.rb
  modified:
    - config/routes.rb
    - config/application.rb
    - app/views/layouts/application.html.erb

key-decisions:
  - "Remove public/404.html and public/500.html: ActionDispatch::Static serves static files before routing, returning 200 status and bypassing ErrorsController entirely — static files must be removed for exceptions_app routing to work"
  - "errors.css loaded unconditionally (outside authenticated? block): error pages shown to both authenticated and unauthenticated users"
  - "allow_unauthenticated_access on ErrorsController: error pages must be accessible to unauthenticated users without triggering the authentication before_action redirect"
  - "maintenance.html uses #0d9488 hex directly: CSS custom properties unavailable outside Rails asset pipeline; hex fallback matches --brand (teal-600)"

patterns-established:
  - "exceptions_app pattern: set config.exceptions_app = self.routes and add match '/404' and '/500' routes at end of routes file"

requirements_covered:
  - id: "ERR-01"
    description: "Branded 404 error page"
    evidence: "app/controllers/errors_controller.rb, app/views/errors/not_found.html.erb"
  - id: "ERR-02"
    description: "Branded 500 error page"
    evidence: "app/controllers/errors_controller.rb, app/views/errors/internal_server_error.html.erb"

duration: 8min
completed: 2026-03-12
---

# Phase 20 Plan 03: Branded Error Pages + Maintenance Summary

**ErrorsController with exceptions_app routing, branded 404/500 views using CSS custom properties, and a self-contained maintenance.html with Plus Jakarta Sans from Google Fonts CDN**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-12T13:30:24Z
- **Completed:** 2026-03-12T13:38:00Z
- **Tasks:** 2
- **Files created:** 6
- **Files modified:** 3

## Accomplishments

- Created `ErrorsController` with `not_found` and `internal_server_error` actions, both accessible without authentication via `allow_unauthenticated_access`
- Wired `config.exceptions_app = self.routes` and added `match '/404'` and `match '/500'` routes so real Rails exceptions route through our branded controller
- Created branded error views with large muted `.error-code` (absolute positioned, `clamp(4rem, 12vw, 8rem)`, `color: var(--brand-light)`) and `.btn-primary` recovery links using `authenticated?` to switch between dashboard and home paths
- Created `errors.css` using only CSS custom properties (no hardcoded hex values)
- Created `public/maintenance.html` as a fully self-contained page with inline styles, Plus Jakarta Sans from Google Fonts CDN, and `#0d9488` teal hex
- All 5 controller tests pass; full suite grows to 500 tests with 0 regressions

## Requirements Covered

| REQ-ID | Requirement | Evidence |
|--------|-------------|----------|
| ERR-01 | Branded 404 error page | `app/views/errors/not_found.html.erb` + `ErrorsController#not_found` |
| ERR-02 | Branded 500 error page | `app/views/errors/internal_server_error.html.erb` + `ErrorsController#internal_server_error` |

## Task Commits

Each task was committed atomically:

1. **Task 1: ErrorsController, routes, application.rb config, error views, errors.css** - `af4fe9d` (feat)
2. **Task 2: public/maintenance.html, controller tests, remove static error pages** - `252fcde` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `app/controllers/errors_controller.rb` — ErrorsController with not_found (404) and internal_server_error (500) actions, allow_unauthenticated_access
- `app/views/errors/not_found.html.erb` — Branded 404 view with .error-code, .error-heading, .error-description, .btn-primary recovery link
- `app/views/errors/internal_server_error.html.erb` — Branded 500 view with same structure, support@asthmabuddy.app contact link
- `app/assets/stylesheets/errors.css` — Error page layout: absolute .error-code behind z-index:1 .error-content, all CSS custom properties
- `public/maintenance.html` — Self-contained maintenance page: inline styles, Google Fonts CDN, #0d9488 hex teal, no JS, no Rails
- `test/controllers/errors_controller_test.rb` — 5 tests: status codes, content selectors, unauthenticated access
- `config/routes.rb` — Added match '/404' and '/500' routes at end of file (via: :all)
- `config/application.rb` — Added config.exceptions_app = self.routes
- `app/views/layouts/application.html.erb` — Added errors stylesheet after legal stylesheet (unconditional)
- ~~`public/404.html`~~ — Deleted (was intercepted by ActionDispatch::Static before routing)
- ~~`public/500.html`~~ — Deleted (same reason)

## Decisions Made

- **Remove `public/404.html` and `public/500.html`**: `ActionDispatch::Static` middleware is early in the stack and serves these static files directly, returning 200 status and bypassing the Rails router entirely. `ErrorsController` routes are never reached while these files exist. Removing them is required for `exceptions_app` routing to function correctly.
- **`errors.css` loaded unconditionally**: Error pages shown to both authenticated and unauthenticated users; stylesheet placed outside `authenticated?` block, after `legal` stylesheet line.
- **`allow_unauthenticated_access` on `ErrorsController`**: Without this, the `Authentication` concern's `before_action` would redirect unauthenticated users away from error pages to the login page — defeating the purpose of branded error handling.
- **`maintenance.html` uses `#0d9488` hex**: CSS custom properties from `application.css` are unavailable in a standalone HTML file served without Rails. Hex value `#0d9488` is the teal-600 value matching `--brand`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed public/404.html and public/500.html**
- **Found during:** Task 2 verification (running tests)
- **Issue:** Tests returned HTTP 200 instead of 404/500. Traced to `ActionDispatch::Static` middleware serving `public/404.html` and `public/500.html` as static files before the request reached the Rails router. The `exceptions_app = self.routes` config was never triggered because the static files short-circuited routing.
- **Fix:** Deleted `public/404.html` and `public/500.html`. These default Rails-generated static error pages are incompatible with `exceptions_app` routing.
- **Files modified:** `public/404.html` (deleted), `public/500.html` (deleted)
- **Verification:** All 5 controller tests pass; `/404` returns HTTP 404, `/500` returns HTTP 500
- **Committed in:** `252fcde` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required for correct error page routing. Removing default static files is standard practice when implementing `exceptions_app`. No scope creep.

## Issues Encountered

- `ActionDispatch::Static` was serving `public/404.html` and `public/500.html` as 200 OK static files, masking the `ErrorsController` routes. Identified by tracing the response body ("The page you were looking for doesn't exist (404 Not found)") which matched the content of the static file.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 20 complete: Legal pages (20-01), persistent cookie dismissal (20-02), and branded error pages (20-03) all delivered
- Phase 21 SEO work can proceed; `ErrorsController` is ready for any further error handling
- `public/maintenance.html` ready for Kamal/nginx to serve during deployments
- 500 integration tests passing, 0 regressions

---
*Phase: 20-legal-pages-cookie-banner-error-pages*
*Completed: 2026-03-12*
