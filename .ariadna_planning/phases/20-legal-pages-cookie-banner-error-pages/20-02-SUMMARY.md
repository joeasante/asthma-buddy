---
phase: 20-legal-pages-cookie-banner-error-pages
plan: 02
subsystem: ui
tags: [rails, cookies, pecr, gdpr, cookie-notice]

# Dependency graph
requires:
  - phase: 16-legal-pages-cookie-banner-error-pages
    provides: CookieNoticesController with session-scoped dismiss action and cookie notice partial/Stimulus/CSS
provides:
  - Persistent 365-day cookie dismissal for cookie notice banner
  - CookieNoticesController#dismiss sets cookies[:cookie_notice_dismissed] with 365-day expiry
  - Application layout condition reads cookies[:cookie_notice_dismissed].present?
affects: [20-03]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Persistent cookie dismissal: cookies[:cookie_notice_dismissed] = { value: '1', expires: 365.days.from_now }"

key-files:
  created: []
  modified:
    - app/controllers/cookie_notices_controller.rb
    - app/views/layouts/application.html.erb
    - test/controllers/cookie_notices_controller_test.rb

key-decisions:
  - "Persistent cookie replaces session flag: cookies[:cookie_notice_dismissed] (365 days) eliminates PECR nuisance of banner reappearing on every new session"
  - "head :no_content response unchanged: Stimulus controller handles client-side hide/remove; no redirect or Turbo Stream needed"

patterns-established: []

requirements_covered: []

# Metrics
duration: 1min
completed: 2026-03-12
---

# Phase 20 Plan 02: Cookie Notice Persistent Dismissal Summary

**Upgraded cookie banner dismissal from session-scoped to a persistent 365-day cookie so the notice never reappears after first dismissal, even across browser sessions.**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-03-12T18:27:45Z
- **Completed:** 2026-03-12T18:28:30Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- `CookieNoticesController#dismiss` now sets `cookies[:cookie_notice_dismissed]` with 365-day expiry, replacing the old `session[:cookie_notice_shown] = true`
- Application layout condition changed from `session[:cookie_notice_shown]` to `cookies[:cookie_notice_dismissed].present?`
- Cookie notice partial, CSS, and Stimulus controller left untouched — only persistence layer changed
- 495 tests passing, 0 regressions

## Task Commits

Each task was committed atomically:

1. **Task 1: Upgrade CookieNoticesController#dismiss to persistent cookie and update layout condition** - `8b87671` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `app/controllers/cookie_notices_controller.rb` - Persistent cookie dismissal with 365-day expiry
- `app/views/layouts/application.html.erb` - Layout condition checks `cookies[:cookie_notice_dismissed].present?`
- `test/controllers/cookie_notices_controller_test.rb` - Updated test to assert persistent cookie (not session flag)

## Decisions Made

- **Persistent cookie replaces session flag**: `cookies[:cookie_notice_dismissed]` (365 days) eliminates PECR nuisance of banner reappearing on every new session. The session cookie itself remains strictly necessary and exempt from consent requirements.
- **`head :no_content` response unchanged**: Stimulus controller handles client-side hide/remove; no redirect or Turbo Stream needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated controller test asserting stale session flag**
- **Found during:** Task 1 (running `bin/rails test` post-implementation)
- **Issue:** `CookieNoticesControllerTest#test_POST_/cookie-notice/dismiss_returns_204_and_sets_session_flag` asserted `session[:cookie_notice_shown]` which is no longer set; test failed after the intentional behaviour change
- **Fix:** Updated test name, assertion, and comment to verify `cookies[:cookie_notice_dismissed].present?`; third test comment updated to remove reference to session flag
- **Files modified:** `test/controllers/cookie_notices_controller_test.rb`
- **Verification:** 3/3 cookie notice controller tests pass; 495 full suite tests pass
- **Committed in:** `8b87671` (included in Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — test asserting replaced behaviour)
**Impact on plan:** Necessary correctness fix. The plan specified changing the implementation; the test had to follow. No scope creep.

## Issues Encountered

None — straightforward two-line implementation change. Test suite caught the stale test assertion immediately.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Cookie notice persistent dismissal complete; ready for Plan 20-03 (Branded Error Pages + Maintenance)
- No blockers

---
*Phase: 20-legal-pages-cookie-banner-error-pages*
*Completed: 2026-03-12*

## Self-Check: PASSED

- FOUND: app/controllers/cookie_notices_controller.rb
- FOUND: app/views/layouts/application.html.erb
- FOUND: test/controllers/cookie_notices_controller_test.rb
- FOUND: .ariadna_planning/phases/20-legal-pages-cookie-banner-error-pages/20-02-SUMMARY.md
- FOUND: commit 8b87671
