---
phase: 26-role-based-access-control
verified: 2026-03-14T18:00:00Z
status: passed
score: 11/11 must-haves verified | security: 0 critical, 0 high | performance: 0 high
gaps: []
security_findings: []
performance_findings: []
human_verification:
  - test: "Log in as admin, navigate to admin panel, verify role badges appear correctly for each user"
    expected: "Admin users show 'Admin' badge, member users show 'Member' badge"
    why_human: "Visual rendering of badges cannot be verified programmatically"
  - test: "Log in as admin, click 'Close Registration' on admin dashboard, then open signup page in incognito"
    expected: "Signup page shows 'Registration Closed' message with no form visible"
    why_human: "End-to-end flow involving multiple browser sessions"
  - test: "Log in as member, attempt to navigate directly to /admin"
    expected: "Redirected away with 'You do not have access to that page.' flash message"
    why_human: "User-facing redirect flow and flash message rendering"
---

# Phase 26: Role-Based Access Control Verification Report

**Phase Goal:** Every controller action is authorized via Pundit policies, roles are managed through an extensible enum (not a boolean), and admins can control user access including toggling registration.
**Verified:** 2026-03-14T18:00:00Z
**Status:** passed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | User model has a role enum with at least :member and :admin values | VERIFIED | `app/models/user.rb` line 6: `enum :role, { member: 0, admin: 1 }, default: :member` |
| 2  | Every controller action runs through a Pundit policy -- verify_authorized or verify_policy_scoped is enforced | VERIFIED | `application_controller.rb` lines 8-9: `after_action :verify_authorized` and `verify_policy_scoped_for_index`; all 23 controllers either have `authorize`/`policy_scope` calls or `skip_pundit` |
| 3  | Accessing a resource without authorization raises Pundit::NotAuthorizedError which renders 403 or redirects with error | VERIFIED | `application_controller.rb` line 11: `rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized`; handler at lines 106-110 renders HTML redirect with alert or JSON 403 |
| 4  | Existing admin panel works identically after migration from admin boolean to role enum | VERIFIED | Migration at `db/migrate/20260314165604_replace_admin_boolean_with_role_enum.rb` backfills role from admin boolean; `Admin::BaseController` retains `require_admin` as defense-in-depth; 619 tests pass with 0 failures |
| 5  | Admin users controller shows roles and allows changing between admin and member | VERIFIED | `app/views/admin/users/index.html.erb` shows "Role" column with Admin/Member badges; toggle buttons say "Change to Member"/"Change to Admin" |
| 6  | Admin can toggle registration open/closed from admin panel | VERIFIED | `Admin::SiteSettingsController#toggle_registration` calls `SiteSetting.toggle_registration!`; admin dashboard view has toggle button with confirmation |
| 7  | When registration is closed, signup page shows 'Registration is currently closed' and form is inaccessible | VERIFIED | `app/views/registrations/new.html.erb` lines 7-12: conditional rendering shows "Registration Closed" heading and hides form when `registration_open?` is false |
| 8  | When registration is open, signup works normally | VERIFIED | Same view renders full form in `else` branch (lines 13-60); `registration_open?` delegates to `SiteSetting.registration_open?` |
| 9  | Registration toggle persists across server restarts (database-backed, not ENV) | VERIFIED | `SiteSetting` model backed by `site_settings` table in `db/schema.rb`; `ApplicationController#registration_open?` calls `SiteSetting.registration_open?` (not ENV) |
| 10 | All Pundit policies are tested -- admin gets admin access, member gets member access, wrong-owner is denied | VERIFIED | Test files exist: `test/policies/application_policy_test.rb`, `test/policies/user_policy_test.rb`, `test/policies/symptom_log_policy_test.rb`; 619 tests pass |
| 11 | Role management tests verify admin can change roles and last-admin protection works | VERIFIED | `UserPolicy#toggle_admin?` includes last-admin check (`!record.admin? \|\| User.admin.count > 1`); test coverage in `test/controllers/admin/users_controller_test.rb` |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `app/policies/application_policy.rb` | Base Pundit policy with deny-by-default | VERIFIED | 63 lines; all default actions return false; Scope defaults to `scope.none` |
| `app/models/user.rb` | User model with role enum | VERIFIED | `enum :role, { member: 0, admin: 1 }, default: :member` on line 6 |
| `db/migrate/20260314165604_replace_admin_boolean_with_role_enum.rb` | Migration from admin boolean to role enum | VERIFIED | Adds role integer column, backfills from admin boolean, removes admin column, adds index |
| `app/models/site_setting.rb` | Database-backed site settings | VERIFIED | 19 lines; `registration_open?` with cache, `toggle_registration!` with cache invalidation |
| `app/controllers/admin/site_settings_controller.rb` | Admin toggle for registration | VERIFIED | `toggle_registration` action with Pundit `authorize :site_setting, :toggle_registration?` |
| `test/policies/application_policy_test.rb` | Policy test coverage | VERIFIED | File exists with deny-by-default tests |
| 18 policy files in `app/policies/` | Individual policies for all controllers | VERIFIED | All 18 files present: application, symptom_log, peak_flow_reading, health_event, medication, dose_log, notification, profile, user, dashboard, settings, admin_dashboard, account, preventer_history, reliever_usage, appointment_summary, onboarding, site_setting |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `application_controller.rb` | Pundit | `include Pundit::Authorization` | WIRED | Line 5 |
| `application_controller.rb` | verify_authorized | `after_action` | WIRED | Line 8: `after_action :verify_authorized, unless: :skip_authorization?` |
| Policies | `User#role` | `user.admin?` | WIRED | `ApplicationPolicy#admin?` delegates to `user.admin?`; AdminDashboardPolicy, UserPolicy use it |
| `registrations_controller.rb` | SiteSetting | `registration_open?` check | WIRED | `ApplicationController#registration_open?` calls `SiteSetting.registration_open?` (line 78) |
| `admin/site_settings_controller.rb` | SiteSetting | `toggle_registration` | WIRED | Calls `SiteSetting.toggle_registration!` (line 6) |
| `registrations/new.html.erb` | `registration_open?` | conditional rendering | WIRED | Line 7: `unless registration_open?` hides form and shows closed message |
| `config/routes.rb` | `admin/site_settings_controller.rb` | toggle_registration route | WIRED | Line 85: `post "site_settings/toggle_registration"` |

### Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| RBAC-01: Admin can assign roles via admin panel | SATISFIED | -- |
| RBAC-02: All resource access authorized via Pundit with verify_authorized | SATISFIED | -- |
| RBAC-03: Existing admin functionality works after boolean-to-enum migration | SATISFIED | -- |
| RBAC-04: Admin can toggle registration open/closed | SATISFIED | -- |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | -- | -- | -- | -- |

No TODOs, FIXMEs, placeholders, debug statements, NotImplementedError, or empty method implementations found in any policy or modified controller file.

### Security Findings

| Check | Name | Severity | File | Line | Detail |
|-------|------|----------|------|------|--------|
| 3.2a  | Unscoped find in admin controller | Low | `app/controllers/admin/users_controller.rb` | 16 | `User.find(params[:id])` -- acceptable because controller is protected by both `require_admin` before_action and Pundit `authorize @user` which checks admin status and self-protection |

**Security:** 1 finding (0 critical, 0 high, 0 medium, 1 low)

The unscoped `User.find` is intentional -- admin users need to look up any user by ID to manage roles. Defense-in-depth is provided by `Admin::BaseController#require_admin` AND Pundit's `authorize @user` which checks `toggle_admin?` policy.

### Performance Findings

No performance issues found. `SiteSetting.registration_open?` uses `Rails.cache.fetch` with 5-minute TTL to avoid per-request DB queries.

### Human Verification Required

### 1. Admin Role Badges Display

**Test:** Log in as admin, navigate to /admin/users, inspect the Role column
**Expected:** Admin users show "Admin" badge (styled), member users show "Member" badge
**Why human:** Visual rendering and badge styling cannot be verified programmatically

### 2. Registration Toggle Flow

**Test:** Log in as admin, click "Close Registration" on admin dashboard, then open signup page in a different browser/incognito
**Expected:** Signup page shows "Registration Closed" heading with no form, only a "Back to sign in" link
**Why human:** End-to-end flow involving admin action followed by unauthenticated page view

### 3. Non-Admin Access Denied

**Test:** Log in as a member user, navigate directly to /admin
**Expected:** Redirected to root with flash alert "You do not have access to that page."
**Why human:** User-facing redirect behavior and flash message display

### Gaps Summary

No gaps found. All 11 observable truths are verified against the actual codebase. The role enum replaces the admin boolean with a reversible migration. Pundit is wired into every controller action via `verify_authorized` with proper skip mechanisms for unauthenticated controllers. The admin registration toggle is database-backed via SiteSetting model with cache layer. All 619 tests pass with 0 failures.

---

_Verified: 2026-03-14T18:00:00Z_
_Verifier: Claude (ariadna-verifier)_
