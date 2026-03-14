---
phase: 26-role-based-access-control
plan: 02
subsystem: auth
tags: [pundit, rbac, registration-toggle, site-settings, rails, minitest]

# Dependency graph
requires:
  - phase: 26-role-based-access-control
    plan: 01
    provides: "Pundit policies, role enum, verify_authorized safety net"
provides:
  - "SiteSetting model with database-backed registration toggle"
  - "Admin registration toggle UI on dashboard"
  - "Registration page conditional rendering (open/closed)"
  - "Comprehensive RBAC test suite (policies, roles, registration toggle)"
affects: [27-multi-factor-authentication, 28-api-layer, 29-billing-subscriptions, 30-integration-tests]

# Tech tracking
tech-stack:
  added: []
  patterns: [database-backed site settings with cache, admin-controlled registration toggle]

key-files:
  created:
    - app/models/site_setting.rb
    - app/policies/site_setting_policy.rb
    - app/controllers/admin/site_settings_controller.rb
    - db/migrate/20260314171218_create_site_settings.rb
    - test/models/site_setting_test.rb
    - test/policies/application_policy_test.rb
    - test/policies/user_policy_test.rb
    - test/policies/symptom_log_policy_test.rb
    - test/controllers/admin/site_settings_controller_test.rb
    - test/fixtures/site_settings.yml
  modified:
    - app/controllers/application_controller.rb
    - app/views/admin/dashboard/index.html.erb
    - app/views/registrations/new.html.erb
    - config/routes.rb
    - db/seeds.rb
    - test/controllers/registrations_controller_test.rb
    - test/controllers/admin/dashboard_controller_test.rb
    - test/controllers/admin/users_controller_test.rb
    - test/models/user_test.rb

key-decisions:
  - "Kept ALLOWED_EMAILS for login restriction in SessionsController, SiteSetting only controls registration"
  - "Used Rails.cache.fetch with 5-minute TTL for registration_open? to avoid per-request DB queries"
  - "Used find_or_create_by! in toggle_registration! for resilience if setting row is missing"

patterns-established:
  - "SiteSetting key/value pattern: database-backed settings with cache layer"
  - "Registration toggle: admin-only via Pundit headless policy"

requirements_covered:
  - id: "RBAC-04"
    description: "Admin can toggle registration open/closed from admin panel"
    evidence: "Admin::SiteSettingsController#toggle_registration, SiteSetting.toggle_registration!, admin dashboard toggle UI"

# Metrics
duration: 4min
completed: 2026-03-14
---

# Phase 26 Plan 02: Registration Toggle and RBAC Test Suite Summary

**Database-backed registration toggle via SiteSetting model with admin dashboard UI, plus 43 new tests covering Pundit policies, role enum, and registration control**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-14T17:12:12Z
- **Completed:** 2026-03-14T17:16:12Z
- **Tasks:** 2
- **Files modified:** 20

## Accomplishments
- Created SiteSetting model with cached registration_open? and toggle_registration! replacing ENV-based approach
- Added admin dashboard registration toggle card with open/closed badge and confirmation dialog
- Updated registration page to show "Registration Closed" message when toggled off
- Added 43 new tests: policy tests (deny-by-default, owner, admin), role enum tests, registration toggle tests

## Requirements Covered
| REQ-ID | Requirement | Evidence |
|--------|-------------|----------|
| RBAC-04 | Admin can toggle registration open/closed from admin panel | `SiteSetting.toggle_registration!` + admin dashboard UI + `SiteSettingPolicy` |

## Task Commits

Each task was committed atomically:

1. **Task 1: SiteSetting model + admin registration toggle + updated registration flow** - `e5c0623` (feat)
2. **Task 2: Comprehensive test suite for RBAC** - `fa99a99` (test)

## Files Created/Modified
- `app/models/site_setting.rb` - Database-backed site settings with cached registration_open? and toggle
- `app/policies/site_setting_policy.rb` - Admin-only policy for site settings
- `app/controllers/admin/site_settings_controller.rb` - Toggle registration action
- `db/migrate/20260314171218_create_site_settings.rb` - SiteSettings table with unique key index
- `app/controllers/application_controller.rb` - registration_open? now uses SiteSetting (kept ALLOWED_EMAILS for login)
- `app/views/admin/dashboard/index.html.erb` - Registration toggle card with status badge
- `app/views/registrations/new.html.erb` - Conditional form/closed message rendering
- `config/routes.rb` - Admin toggle_registration route
- `test/models/site_setting_test.rb` - SiteSetting model tests (6 tests)
- `test/policies/application_policy_test.rb` - Deny-by-default tests (6 tests)
- `test/policies/user_policy_test.rb` - Admin/member policy tests (8 tests)
- `test/policies/symptom_log_policy_test.rb` - Owner-based policy tests (8 tests)
- `test/controllers/admin/site_settings_controller_test.rb` - Toggle controller tests (4 tests)
- `test/controllers/registrations_controller_test.rb` - Registration toggle tests (4 new tests)
- `test/controllers/admin/dashboard_controller_test.rb` - Site settings section test (1 new test)
- `test/controllers/admin/users_controller_test.rb` - Last-admin protection test (1 new test)
- `test/models/user_test.rb` - Role enum tests (4 new tests)
- `test/fixtures/site_settings.yml` - Default registration_open fixture

## Decisions Made
- Kept `allowed_emails` and `allowed_email?` in ApplicationController for SessionsController login restriction (ALLOWED_EMAILS ENV var still controls who can log in)
- Used `SiteSetting.registration_open?` with 5-minute cache TTL to avoid per-request DB queries
- Used `find_or_create_by!` in `toggle_registration!` for resilience if the setting row is missing
- Added site_settings fixture as part of Task 1 (Rule 3 deviation) to prevent existing test breakage

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Created site_settings fixture in Task 1 instead of Task 2**
- **Found during:** Task 1 (after migration)
- **Issue:** Existing registration controller tests failed because SiteSetting.registration_open? returns false when no row exists in test DB
- **Fix:** Created test/fixtures/site_settings.yml with registration_open: "true" as part of Task 1
- **Files modified:** test/fixtures/site_settings.yml
- **Verification:** All 576 existing tests pass
- **Committed in:** e5c0623 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Fixture creation moved from Task 2 to Task 1 to prevent test breakage. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviation above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- RBAC phase is complete: role enum, Pundit policies, registration toggle, full test coverage
- Phase 27 (MFA) can build on the role/auth foundation
- Phase 28 (API) can reuse existing Pundit policies for API authorization
- Phase 29 (Billing) can add subscription checks to existing policies

## Self-Check: PASSED

All 10 created files verified present. Both task commits (e5c0623, fa99a99) verified in git history.

---
*Phase: 26-role-based-access-control*
*Completed: 2026-03-14*
