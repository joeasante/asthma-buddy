---
phase: 26-role-based-access-control
plan: 01
subsystem: auth
tags: [pundit, rbac, authorization, role-enum, rails]

# Dependency graph
requires:
  - phase: 24-admin-observability
    provides: "Admin panel with admin boolean on User model"
provides:
  - "User model with role enum (member/admin) replacing admin boolean"
  - "Pundit gem installed with deny-by-default ApplicationPolicy"
  - "Pundit policies for all 17 controllers"
  - "verify_authorized safety net on ApplicationController"
  - "skip_pundit mechanism for unauthenticated controllers"
affects: [27-multi-factor-authentication, 28-api-layer, 29-billing-subscriptions, 30-integration-tests]

# Tech tracking
tech-stack:
  added: [pundit 2.5.2]
  patterns: [deny-by-default authorization, headless policies for non-model controllers, skip_pundit class method for unauthenticated controllers]

key-files:
  created:
    - app/policies/application_policy.rb
    - app/policies/symptom_log_policy.rb
    - app/policies/peak_flow_reading_policy.rb
    - app/policies/health_event_policy.rb
    - app/policies/medication_policy.rb
    - app/policies/dose_log_policy.rb
    - app/policies/notification_policy.rb
    - app/policies/profile_policy.rb
    - app/policies/user_policy.rb
    - app/policies/dashboard_policy.rb
    - app/policies/settings_policy.rb
    - app/policies/admin_dashboard_policy.rb
    - app/policies/account_policy.rb
    - app/policies/preventer_history_policy.rb
    - app/policies/reliever_usage_policy.rb
    - app/policies/appointment_summary_policy.rb
    - app/policies/onboarding_policy.rb
    - db/migrate/20260314165604_replace_admin_boolean_with_role_enum.rb
  modified:
    - app/models/user.rb
    - app/controllers/application_controller.rb
    - app/controllers/admin/users_controller.rb
    - app/views/admin/users/index.html.erb

key-decisions:
  - "Used class_attribute :_skip_pundit for skip mechanism instead of skip_after_action (cleaner, inheritable)"
  - "Kept Admin::BaseController require_admin as defense-in-depth alongside Pundit"
  - "Used headless policies (symbol-based authorize) for controllers without model records"
  - "Used verify_policy_scoped_for_index custom callback to avoid action-existence validation errors"
  - "Defined pundit_user to map to Current.user (app does not define current_user)"

patterns-established:
  - "Owner-based policy pattern: record.user == user for CRUD on user-owned resources"
  - "Headless policy pattern: authorize :symbol, :action? for controllers without ActiveRecord models"
  - "skip_pundit class method: call in any controller to opt out of Pundit verification"
  - "Settings child controllers: self._skip_pundit = false to re-enable Pundit (parent skips)"

requirements_covered:
  - id: "RBAC-01"
    description: "Admin can assign roles (admin/member) to users via the admin panel"
    evidence: "app/controllers/admin/users_controller.rb#toggle_admin, app/policies/user_policy.rb#toggle_admin?"
  - id: "RBAC-02"
    description: "All resource access authorized via Pundit policies with verify_authorized safety net"
    evidence: "app/controllers/application_controller.rb (after_action :verify_authorized), 17 policy files in app/policies/"
  - id: "RBAC-03"
    description: "Existing admin functionality continues working after migration from boolean to role enum"
    evidence: "db/migrate/20260314165604_replace_admin_boolean_with_role_enum.rb, all 576 tests pass"

# Metrics
duration: 13min
completed: 2026-03-14
---

# Phase 26 Plan 01: Role-Based Access Control Summary

**Pundit authorization with deny-by-default policies for all 17 controllers, role enum replacing admin boolean, and verify_authorized safety net**

## Performance

- **Duration:** 13 min
- **Started:** 2026-03-14T16:55:43Z
- **Completed:** 2026-03-14T17:08:43Z
- **Tasks:** 3
- **Files modified:** 52

## Accomplishments
- Replaced admin boolean with role enum (member: 0, admin: 1) via reversible migration with backfill
- Installed Pundit 2.5.2 with deny-by-default ApplicationPolicy and 17 individual policies
- Added verify_authorized/verify_policy_scoped enforcement on ApplicationController
- Updated admin panel to show role badges and role-change buttons with last-admin protection via Pundit policy

## Requirements Covered
| REQ-ID | Requirement | Evidence |
|--------|-------------|----------|
| RBAC-01 | Admin can assign roles via admin panel | `Admin::UsersController#toggle_admin` + `UserPolicy#toggle_admin?` |
| RBAC-02 | All resource access authorized via Pundit with verify_authorized | `ApplicationController` after_action + 17 policy files |
| RBAC-03 | Existing admin functionality works after boolean-to-enum migration | Migration + all 576 tests pass |

## Task Commits

Each task was committed atomically:

1. **Task 1: Role enum migration + Pundit gem + base policies** - `cc488ce` (feat)
2. **Task 2: ApplicationController Pundit setup + unauthenticated skips** - `fd616ff` (feat)
3. **Task 3: Authorize calls in controllers + admin view updates** - `42bae1a` (feat)

## Files Created/Modified
- `app/policies/application_policy.rb` - Deny-by-default base policy with owner? helper
- `app/policies/*.rb` (17 files) - Individual policies for all controllers
- `db/migrate/20260314165604_replace_admin_boolean_with_role_enum.rb` - Admin boolean to role enum migration
- `app/models/user.rb` - Added role enum (member: 0, admin: 1)
- `app/controllers/application_controller.rb` - Pundit::Authorization, verify_authorized, rescue_from, skip_pundit mechanism, pundit_user
- `app/controllers/admin/users_controller.rb` - Role enum toggle, Pundit authorize calls
- `app/views/admin/users/index.html.erb` - Role column, Member badge, role-change buttons

## Decisions Made
- Used `class_attribute :_skip_pundit` for skip mechanism instead of `skip_after_action` (cleaner, inheritable)
- Kept `Admin::BaseController#require_admin` as defense-in-depth alongside Pundit policies
- Used headless policies (symbol-based `authorize :dashboard, :index?`) for controllers without model records
- Created custom `verify_policy_scoped_for_index` callback to avoid `AbstractController::ActionNotFound` when `only: :index` validates action existence on controllers without index
- Defined `pundit_user` mapping to `Current.user` since the app doesn't define `current_user`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added pundit_user method for Current.user mapping**
- **Found during:** Task 3 (adding authorize calls)
- **Issue:** Pundit calls `current_user` by default, but this app uses `Current.user` via the Authentication concern
- **Fix:** Added `pundit_user` method to ApplicationController returning `Current.user`
- **Files modified:** `app/controllers/application_controller.rb`
- **Verification:** All 576 tests pass
- **Committed in:** `42bae1a` (Task 3 commit)

**2. [Rule 1 - Bug] Fixed verify_policy_scoped causing ActionNotFound**
- **Found during:** Task 2 (Pundit setup)
- **Issue:** `after_action :verify_policy_scoped, only: :index` raises `AbstractController::ActionNotFound` on controllers without an `index` action (SessionsController, etc.) even when `unless: :skip_authorization?` is set, because Rails validates action existence at class load time
- **Fix:** Replaced with custom `verify_policy_scoped_for_index` that checks `action_name == "index"` at runtime
- **Files modified:** `app/controllers/application_controller.rb`
- **Verification:** All 576 tests pass; unauthenticated controllers no longer raise
- **Committed in:** `fd616ff` (Task 2 commit)

**3. [Rule 3 - Blocking] Re-enabled Pundit in Settings child controllers**
- **Found during:** Task 3 (adding authorize calls)
- **Issue:** `Settings::BaseController` has `skip_pundit` (no actions of its own), but child controllers inherit it via `class_attribute`, silently skipping all authorization
- **Fix:** Added `self._skip_pundit = false` to `Settings::MedicationsController`, `Settings::DoseLogsController`, `Settings::AccountsController`
- **Files modified:** Three Settings child controllers
- **Verification:** All 576 tests pass; Pundit enforces authorization in all Settings child controllers
- **Committed in:** `42bae1a` (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (1 bug, 2 blocking)
**Impact on plan:** All auto-fixes necessary for correctness. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Role enum and Pundit policies are the authorization foundation for all SaaS features
- API layer (Phase 28) can reuse the same policies for API controllers
- Billing (Phase 29) can add subscription-based checks to existing policies
- RBAC-04 (toggle registration) is not covered by this plan and should be addressed separately

---
*Phase: 26-role-based-access-control*
*Completed: 2026-03-14*
