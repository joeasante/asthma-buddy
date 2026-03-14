---
phase: 27-multi-factor-authentication
plan: 02
subsystem: auth
tags: [mfa, totp, controllers, views, security-settings, qr-code, recovery-codes]

# Dependency graph
requires:
  - phase: 27-multi-factor-authentication
    provides: User model MFA methods (enable_mfa!, disable_mfa!, verify_otp, verify_recovery_code)
  - phase: 02-authentication
    provides: SessionsController, Authentication concern, start_new_session_for
  - phase: 26-role-based-access-control
    provides: Pundit authorization, skip_pundit, SettingsPolicy
provides:
  - "MfaChallengeController with TOTP + recovery code verification, rate limiting, 5-min expiry"
  - "Settings::SecurityController with full MFA lifecycle (setup, confirm, recovery codes, disable, regenerate)"
  - "SessionsController pending MFA state redirect for MFA-enabled users"
  - "MfaHelper for QR code SVG generation"
  - "All MFA views styled with Asthma Buddy design system"
  - "Security nav card on Settings page with MFA status badge"
affects: [27-03, mfa-tests, integration-tests]

# Tech tracking
tech-stack:
  added: []
  patterns: [pending MFA session state, password re-auth for destructive MFA actions, inline SVG QR codes]

key-files:
  created:
    - app/controllers/mfa_challenge_controller.rb
    - app/controllers/settings/security_controller.rb
    - app/helpers/mfa_helper.rb
    - app/views/mfa_challenge/new.html.erb
    - app/views/settings/security/show.html.erb
    - app/views/settings/security/setup.html.erb
    - app/views/settings/security/recovery_codes.html.erb
    - app/views/settings/security/disable.html.erb
    - app/views/settings/security/regenerate_recovery_codes.html.erb
  modified:
    - config/routes.rb
    - app/controllers/sessions_controller.rb
    - app/models/user.rb
    - app/views/settings/show.html.erb
    - app/assets/stylesheets/settings.css

key-decisions:
  - "Used controller: 'security' in routes to avoid Rails inflecting resource :security to SecuritiesController"
  - "Added regenerate_recovery_codes! to User model (not in Plan 01 scope, needed by controller)"
  - "Reused SettingsPolicy :show? for all security actions (user-scoped, no special policy needed)"
  - "Recovery code pattern field accepts alphanumeric to support both TOTP codes and recovery codes in same input"

patterns-established:
  - "Pending MFA session pattern: session[:pending_mfa_user_id] + session[:pending_mfa_at] with 5-min TTL"
  - "Password re-auth pattern for destructive security actions (disable MFA, regenerate codes)"
  - "MFA setup flow: pending secret in session, never written to DB until verification confirmed"

# Metrics
duration: 6min
completed: 2026-03-14
---

# Phase 27 Plan 02: MFA Controllers and Views Summary

**Full MFA user flow with security settings controller, login challenge controller, pending session state, QR setup, recovery codes, and design-system-styled views**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-14T20:15:50Z
- **Completed:** 2026-03-14T20:21:50Z
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments
- Built MfaChallengeController with rate limiting (5/min), TOTP + recovery code verification, and 5-minute session expiry
- Modified SessionsController to intercept MFA-enabled users into pending state before authentication
- Built Settings::SecurityController with complete MFA lifecycle: setup with QR code, confirm, recovery codes (view + download), disable, regenerate
- Created 7 views styled with Asthma Buddy design system (auth-card pattern, section-card pattern, page headers)
- Added Security nav card to Settings page with dynamic MFA status badge
- Added MFA-specific CSS: setup steps with numbered circles, QR container, warning cards, recovery code grid

## Task Commits

Each task was committed atomically:

1. **Task 1: Routes, controllers, and helper** - `9e3c91f` (feat)
2. **Task 2: Views and settings page Security card** - `ed4b91b` (feat)

## Files Created/Modified
- `app/controllers/mfa_challenge_controller.rb` - Post-login TOTP/recovery code verification with rate limiting
- `app/controllers/settings/security_controller.rb` - Full MFA lifecycle management
- `app/controllers/sessions_controller.rb` - Pending MFA redirect for MFA-enabled users
- `app/helpers/mfa_helper.rb` - QR code SVG generation via RQRCode
- `app/models/user.rb` - Added regenerate_recovery_codes! method
- `config/routes.rb` - MFA challenge and security settings routes
- `app/views/mfa_challenge/new.html.erb` - TOTP code entry form (auth-card pattern)
- `app/views/settings/security/show.html.erb` - Security settings with MFA status
- `app/views/settings/security/setup.html.erb` - QR code setup with step-by-step instructions
- `app/views/settings/security/recovery_codes.html.erb` - Recovery codes grid with download
- `app/views/settings/security/disable.html.erb` - Password re-auth for MFA disable
- `app/views/settings/security/regenerate_recovery_codes.html.erb` - Password re-auth for code regeneration
- `app/views/settings/show.html.erb` - Added Security nav card
- `app/assets/stylesheets/settings.css` - MFA-specific CSS components

## Decisions Made
- Used `controller: "security"` in routes to prevent Rails from inflecting `resource :security` to `SecuritiesController`
- Added `regenerate_recovery_codes!` to User model (missing from Plan 01, needed by SecurityController)
- Reused SettingsPolicy `:show?` for all security actions per research recommendation
- Set pattern field to accept alphanumeric characters (not just digits) so same input works for both TOTP and recovery codes

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed route controller inflection for security resource**
- **Found during:** Task 1 (Routes)
- **Issue:** `resource :security` inflects controller name to `SecuritiesController`, but controller is named `SecurityController`
- **Fix:** Added `controller: "security"` option to the resource declaration
- **Files modified:** config/routes.rb
- **Verification:** `bin/rails runner "puts 'OK'"` boots successfully, routes resolve correctly
- **Committed in:** 9e3c91f (Task 1 commit)

**2. [Rule 2 - Missing Critical] Added regenerate_recovery_codes! to User model**
- **Found during:** Task 1 (SecurityController)
- **Issue:** SecurityController calls `Current.user.regenerate_recovery_codes!` but method didn't exist on User model (Plan 01 didn't include it)
- **Fix:** Added `regenerate_recovery_codes!` method that generates 10 new codes and persists them
- **Files modified:** app/models/user.rb
- **Verification:** All 634 tests pass
- **Committed in:** 9e3c91f (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical)
**Impact on plan:** Both fixes necessary for correct operation. No scope creep.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Full MFA flow functional: setup, login challenge, disable, recovery code management
- Ready for Plan 03 (controller/integration tests and enforcement verification)
- All 634 tests passing with zero regressions

---
*Phase: 27-multi-factor-authentication*
*Completed: 2026-03-14*
