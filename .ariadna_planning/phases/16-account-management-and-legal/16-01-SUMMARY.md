---
phase: 16-account-management-and-legal
plan: 01
subsystem: auth
tags: [rails, account-deletion, gdpr, settings, minitest]

# Dependency graph
requires:
  - phase: 02-authentication
    provides: Authentication system, Current.user, session management
  - phase: 10-medications
    provides: dependent associations on User model (medications, dose_logs)
  - phase: 15-health-events
    provides: health_events dependent association on User model
provides:
  - AccountsController#destroy with typed DELETE confirmation guard
  - DELETE /account route (account_path)
  - Danger Zone section on settings page with permanent deletion form
  - SettingsController renders settings page (no longer redirects)
affects: [settings, auth, profile]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Typed confirmation guard pattern: params[:confirmation] == "DELETE" before destructive action
    - reset_session after user.destroy to invalidate the active session cookie
    - data: { turbo: false } on deletion form to avoid Turbo intercepting session-reset redirect

key-files:
  created:
    - app/controllers/accounts_controller.rb
    - test/controllers/accounts_controller_test.rb
  modified:
    - app/views/settings/show.html.erb
    - app/controllers/settings_controller.rb
    - config/routes.rb
    - test/controllers/settings_controller_test.rb

key-decisions:
  - "SessionsController returns 302 redirect (not 422) on bad credentials — test assertion corrected to assert_redirected_to new_session_path with alert"
  - "SettingsController#show now renders settings page instead of redirecting to profile_path"
  - "data: { turbo: false } on danger zone form — session reset redirect must bypass Turbo Frame navigation"
  - "reset_session called after Current.user.destroy — invalidates the active session cookie without a separate session destroy call"

patterns-established:
  - "Typed confirmation guard: compare params[:confirmation] == 'DELETE' before any destructive account action"
  - "data: { confirm: false } on submit button prevents Stimulus confirm controller from intercepting the typed-confirmation form"

requirements_covered:
  - id: "ACC-01"
    description: "GDPR right to erasure — user can permanently delete their account"
    evidence: "AccountsController#destroy with Current.user.destroy cascade"
  - id: "ACC-02"
    description: "All associated health data deleted on account deletion"
    evidence: "User model has dependent: :destroy on all associations"

# Metrics
duration: 10min
completed: 2026-03-10
---

# Phase 16 Plan 01: Account Deletion Summary

**AccountsController#destroy with typed DELETE confirmation guard, Danger Zone section on settings page, full cascade via dependent: :destroy on all User associations**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-10T14:40:00Z
- **Completed:** 2026-03-10T14:50:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Created AccountsController with destroy action guarded by typed "DELETE" confirmation
- Added `resource :account, only: [:destroy]` route — `DELETE /account` maps to `accounts#destroy`
- Added Danger Zone section to settings/show.html.erb with accessible form using typed confirmation
- Updated SettingsController#show to render the settings page (removed redirect to profile_path)
- 5 AccountsController tests: correct/wrong/empty confirmation, unauthenticated, deleted user sign-in attempt
- 2 updated SettingsController tests: render (not redirect) assertion

## Requirements Covered

| REQ-ID | Requirement | Evidence |
|--------|-------------|----------|
| ACC-01 | GDPR right to erasure — permanent account deletion | `AccountsController#destroy` + `Current.user.destroy` |
| ACC-02 | All health data deleted with account | User model `dependent: :destroy` on all 7 associations |

## Task Commits

Each task was committed atomically:

1. **Task 1: AccountsController#destroy and route** - `ba8bbba` (feat)
2. **Task 2: Danger Zone section and controller tests** - `936cfa6` (feat)

## Files Created/Modified

- `app/controllers/accounts_controller.rb` - AccountsController with destroy action, typed confirmation guard, reset_session
- `config/routes.rb` - Added `resource :account, only: [:destroy]`
- `app/views/settings/show.html.erb` - Danger Zone section with accessible confirmation form at bottom
- `app/controllers/settings_controller.rb` - Removed redirect, now renders settings page
- `test/controllers/accounts_controller_test.rb` - 5 tests covering destroy action
- `test/controllers/settings_controller_test.rb` - Updated to assert render not redirect

## Decisions Made

- **SessionsController returns 302 redirect on bad credentials** — The plan's test asserted `assert_response :unprocessable_entity` (422) but SessionsController#create returns a redirect to `new_session_path` with an alert when authentication fails. Test corrected to `assert_redirected_to new_session_path` with flash alert assertion.
- **SettingsController#show now renders** — Previously redirected to `profile_path`; removing the redirect allows the settings page to serve as a hub showing the Danger Zone alongside the profile nav card.
- **data: { turbo: false } on form** — Required so the post-deletion redirect to root_path (which resets session state) is handled as a full page navigation rather than a Turbo fetch.
- **reset_session after destroy** — Invalidates the session cookie immediately after the user record is deleted, preventing any orphaned session from being reused.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected test assertion for deleted-user sign-in attempt**

- **Found during:** Task 2 (controller test execution)
- **Issue:** Plan test used `assert_response :unprocessable_entity` (422) but `SessionsController#create` returns `redirect_to new_session_path, alert: "Try another email address or password."` (302) when `User.authenticate_by` returns nil — user no longer exists after deletion
- **Fix:** Changed assertion to `assert_redirected_to new_session_path` and added `assert_equal "Try another email address or password.", flash[:alert]`
- **Files modified:** `test/controllers/accounts_controller_test.rb`
- **Verification:** All 7 tests pass after fix
- **Committed in:** `936cfa6` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Test assertion corrected to match actual controller behaviour. Test intent (verifying deleted user cannot sign in) is preserved and now correctly asserts the redirect response. No scope creep.

## Issues Encountered

None beyond the test assertion correction documented in Deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Account deletion fully functional with GDPR-compliant cascade
- Settings page now renders as a hub (profile nav card + Danger Zone section)
- `account_path` route available for any future account management plans
- Phase 16 Plan 02 (legal pages) and Phase 16 Plan 03 (cookie notice) may proceed independently

---
*Phase: 16-account-management-and-legal*
*Completed: 2026-03-10*
