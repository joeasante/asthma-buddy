---
phase: 20-legal-pages-cookie-banner-error-pages
plan: 01
subsystem: ui
tags: [rails, legal, gdpr, pecr, css, cookies]

# Dependency graph
requires:
  - phase: 16-legal-pages
    provides: PagesController with privacy/terms actions and UK GDPR legal copy
provides:
  - Cookie Policy page at GET /cookies (unauthenticated, UK GDPR/PECR compliant)
  - legal.css with .main--narrow 680px narrow layout, .legal-date, .legal-back-link, prose typography
  - All three legal pages wrapped in .main--narrow container
  - cookies_path named helper linked in both footer variants
affects:
  - 20-02 (cookie banner persistence — references cookies page)
  - 20-03 (error pages — uses same legal.css patterns)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Legal page narrow layout via .main--narrow container wrapping .page-header + .section-card"
    - "legal.css loaded unconditionally in application layout (public pages need it before authentication)"
    - "PagesController allow_unauthenticated_access covers all actions including new cookies action"

key-files:
  created:
    - app/views/pages/cookies.html.erb
    - app/assets/stylesheets/legal.css
  modified:
    - app/controllers/pages_controller.rb
    - config/routes.rb
    - app/views/pages/terms.html.erb
    - app/views/pages/privacy.html.erb
    - app/views/layouts/application.html.erb

key-decisions:
  - "legal.css loaded unconditionally (outside authenticated? block) — legal pages are public and need narrow layout before login"
  - "cookies action body is empty (implicit render) — PagesController allow_unauthenticated_access covers it automatically"
  - "Replaced .pages-updated with .legal-date on terms and privacy — consistent class naming across all three legal pages"
  - "Privacy policy section 8 updated with cookies_path link to new Cookie Policy page"

patterns-established:
  - "Legal page pattern: content_for :title → .main--narrow → .page-header → .section-card → .legal-date → h2 sections → .legal-back-link"

requirements_covered: []

# Metrics
duration: 3min
completed: 2026-03-12
---

# Phase 20 Plan 01: Legal Pages & CSS Summary

**Cookie Policy page with UK GDPR/PECR content, legal.css narrow prose layout (680px), and Cookies link added to both authenticated and public footers.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-12T18:23:26Z
- **Completed:** 2026-03-12T18:26:04Z
- **Tasks:** 2
- **Files modified:** 7 (2 created, 5 modified)

## Accomplishments
- Created `GET /cookies` route with `pages#cookies` action; page accessible without authentication
- Created `cookies.html.erb` with full UK GDPR/PECR Cookie Policy — two cookies listed (session + cookie_notice_dismissed), no analytics/tracking declaration, PECR rights, ICO reference, `privacy@asthmabuddy.app` contact
- Created `legal.css` with `.main--narrow` (max-width 680px), `.legal-date`, `.legal-back-link`, and prose typography using only CSS custom properties
- Applied `.main--narrow` wrapper to all three legal pages (terms, privacy, cookies) — consistent narrow layout
- Added `<%= link_to "Cookies", cookies_path %>` to both authenticated footer (`.footer-app`) and public footer
- 495 tests passing, 0 regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: Cookie Policy page — PagesController action, route, and cookies.html.erb** - `7a524a3` (feat)
2. **Task 2: legal.css, apply narrow layout to Terms/Privacy, add Cookies link to footers** - `e230a32` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `app/views/pages/cookies.html.erb` - Full UK GDPR/PECR Cookie Policy with two named cookies, durations, classifications, PECR rights section, and ICO contact
- `app/assets/stylesheets/legal.css` - Narrow prose layout for legal pages; uses only CSS custom properties
- `app/controllers/pages_controller.rb` - Added empty `cookies` action (allow_unauthenticated_access covers it)
- `config/routes.rb` - Added `get "cookies", to: "pages#cookies", as: :cookies`
- `app/views/pages/terms.html.erb` - Wrapped in `.main--narrow`; `.pages-updated` → `.legal-date`; added `.legal-back-link`
- `app/views/pages/privacy.html.erb` - Wrapped in `.main--narrow`; `.pages-updated` → `.legal-date`; added `.legal-back-link`; section 8 links to Cookie Policy
- `app/views/layouts/application.html.erb` - Loads `legal.css` unconditionally; Cookies link added to both footer variants

## Decisions Made
- `legal.css` loaded unconditionally — legal pages are public and must have the narrow layout before a user ever authenticates
- `cookies` action has no body because `allow_unauthenticated_access` at the class level already covers it; implicit render handles the view
- Replaced `.pages-updated` with `.legal-date` on existing terms and privacy views to achieve consistent class naming across all three legal pages
- Privacy Policy section 8 updated to include a `cookies_path` link to the new dedicated Cookie Policy page

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## Self-Check: PASSED

- FOUND: app/views/pages/cookies.html.erb
- FOUND: app/assets/stylesheets/legal.css
- FOUND: app/controllers/pages_controller.rb
- FOUND: commit 7a524a3
- FOUND: commit e230a32

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness
- Plan 20-02 (Cookie Notice → Persistent Dismissal) can proceed; `cookies_path` named helper is now available for the cookie notice banner's "learn more" link if desired
- Plan 20-03 (Branded Error Pages) can proceed; `legal.css` is loaded and available

---
*Phase: 20-legal-pages-cookie-banner-error-pages*
*Completed: 2026-03-12*
