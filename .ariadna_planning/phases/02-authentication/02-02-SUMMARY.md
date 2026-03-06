---
phase: 02-authentication
plan: 02
subsystem: auth
tags: [email-verification, mailer, action-mailer, generates_token_for, login-gate]

# Dependency graph
requires:
  - phase: 02-authentication
    plan: 01
    provides: User model with email_verified_at column, SessionsController, RegistrationsController, fixtures (verified_user/unverified_user)

provides:
  - UserMailer with email_verification action (HTML + text views)
  - EmailVerificationsController#show handling token clicks with valid/already-verified/invalid/expired cases
  - Login gate in SessionsController blocking unverified users with clear error message
  - deliver_later hook in RegistrationsController sending verification email on signup
  - 37 passing tests (up from 28): 3 mailer, 4 verification controller, +1 session, +1 registration

affects:
  - 02-03 (route guards extend same auth pattern; verified users can now log in)

# Tech tracking
tech-stack:
  added: [Action Mailer, generates_token_for (Rails 7.1+ stateless signed token API)]
  patterns:
    - generates_token_for :email_verification with 24h expiry — stateless, no extra DB column
    - deliver_later for non-blocking email dispatch after signup
    - travel helper in tests for expiry verification
    - assert_enqueued_emails for mailer job assertions

key-files:
  created:
    - app/mailers/user_mailer.rb
    - app/views/user_mailer/email_verification.html.erb
    - app/views/user_mailer/email_verification.text.erb
    - app/controllers/email_verifications_controller.rb
    - test/mailers/user_mailer_test.rb
    - test/controllers/email_verifications_controller_test.rb
  modified:
    - app/models/user.rb (added generates_token_for :email_verification)
    - app/controllers/registrations_controller.rb (deliver_later after save)
    - app/controllers/sessions_controller.rb (email_verified_at gate)
    - config/routes.rb (added email_verification/:token route)
    - test/controllers/sessions_controller_test.rb (added unverified rejection test)
    - test/controllers/registrations_controller_test.rb (added enqueued_emails test)

key-decisions:
  - "Custom GET route /email_verification/:token used instead of singular resource :email_verification — singular resource show has no ID segment so param: :token has no effect on the path"
  - "generates_token_for :email_verification chosen over database token column — stateless signed tokens expire automatically, no migration or column needed"
  - "deliver_later used for non-blocking signup flow — verification email processed by Solid Queue background worker"

# Metrics
duration: 3min
completed: 2026-03-06
---

# Phase 2 Plan 02: Email Verification Summary

**Email verification gate using Rails 7.1+ generates_token_for stateless tokens — signup sends verification email via deliver_later, login blocked until email_verified_at set, 37 tests green**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-06T21:25:48Z
- **Completed:** 2026-03-06T21:28:41Z
- **Tasks:** 2 of 2
- **Files modified:** 12

## Accomplishments

- Added `generates_token_for :email_verification, expires_in: 24.hours` to User model — stateless self-expiring signed tokens, no extra DB column needed
- Created UserMailer with HTML and text email views; token embedded in verification URL path
- Created EmailVerificationsController handling all token states: valid (sets email_verified_at), already verified, invalid/expired
- Added `/email_verification/:token` route (custom GET route — not singular resource, which lacks ID segment)
- Gated SessionsController#create on `email_verified_at.present?` — unverified users blocked with clear message
- Wired `UserMailer.email_verification(@user).deliver_later` in RegistrationsController#create
- All 37 tests pass: 3 mailer + 4 verification controller + 1 session gate + 1 registration enqueue

## Task Commits

Each task was committed atomically:

1. **Task 1: Add email verification mailer, controller, and login gate** - `10105bc` (feat)
2. **Task 2: Add mailer tests and email verification integration tests** - `c56dffa` (feat)

## Files Created/Modified

- `app/models/user.rb` - Added `generates_token_for :email_verification, expires_in: 24.hours`
- `app/mailers/user_mailer.rb` - UserMailer with email_verification action
- `app/views/user_mailer/email_verification.html.erb` - HTML email template with verify link
- `app/views/user_mailer/email_verification.text.erb` - Plain text email template
- `app/controllers/email_verifications_controller.rb` - Handles token clicks; valid/already-verified/invalid cases
- `app/controllers/sessions_controller.rb` - Added email_verified_at gate before starting session
- `app/controllers/registrations_controller.rb` - Added deliver_later call after user.save
- `config/routes.rb` - Added `get "email_verification/:token"` route
- `test/mailers/user_mailer_test.rb` - 3 tests: recipient, subject, URL in body
- `test/controllers/email_verifications_controller_test.rb` - 4 tests: valid, already-verified, invalid, expired
- `test/controllers/sessions_controller_test.rb` - Added unverified user rejection test (6 tests total)
- `test/controllers/registrations_controller_test.rb` - Added assert_enqueued_emails test (6 tests total)

## Decisions Made

- **Custom GET route instead of singular resource**: `resource :email_verification, only: [:show], param: :token` produces `GET /email_verification` with no token in path (singular resource show has no ID segment). Used `get "email_verification/:token", to: "email_verifications#show", as: :email_verification` instead — produces correct `GET /email_verification/:token`.
- **generates_token_for over DB column**: Stateless signed token approach means no migration, no cleanup job needed. Token includes user state (email_address, password_digest) so it auto-invalidates if user changes password.
- **deliver_later for async dispatch**: Keeps signup fast; Solid Queue handles delivery in background.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Custom route required for token in path**
- **Found during:** Task 1 (verifying routes)
- **Issue:** Plan specified `resource :email_verification, only: [:show], param: :token` but singular resource `show` doesn't include an ID/param segment in the URL. Route produced was `GET /email_verification` with no token path segment.
- **Fix:** Replaced with explicit `get "email_verification/:token", to: "email_verifications#show", as: :email_verification` — produces `GET /email_verification/:token`
- **Files modified:** `config/routes.rb`
- **Commit:** `10105bc`

**2. [Rule 1 - Bug] Test assertion pattern used query param syntax**
- **Found during:** Task 2 (running mailer tests)
- **Issue:** Test asserted `/token=/` but the URL uses a path segment (`/email_verification/<token>`), not a query param.
- **Fix:** Updated assertion to `/email_verification\/[A-Za-z0-9+\/=_\-]+/` matching the path-based token format
- **Files modified:** `test/mailers/user_mailer_test.rb`
- **Commit:** `c56dffa`

---

**Total deviations:** 2 auto-fixed (both Rule 1 bugs)
**Impact on plan:** Both fixes necessary for correct routing and test assertions. No scope creep.

## Issues Encountered

None beyond the auto-fixed deviations above.

## User Setup Required

None — development.rb already had `config.action_mailer.default_url_options = { host: "localhost", port: 3000 }`. Test environment had `host: "example.com"`. No additional configuration needed.

## Next Phase Readiness

- Email verification complete: signup → email → click link → verified → login works
- Unverified users blocked from login with clear message directing them to check inbox
- Authentication concern and email_verified_at gate in place, ready for 02-03 route guards
- All 37 tests green

---
*Phase: 02-authentication*
*Completed: 2026-03-06*

## Self-Check: PASSED

All key files verified present:
- app/models/user.rb (generates_token_for added)
- app/mailers/user_mailer.rb
- app/views/user_mailer/email_verification.html.erb
- app/views/user_mailer/email_verification.text.erb
- app/controllers/email_verifications_controller.rb
- test/mailers/user_mailer_test.rb
- test/controllers/email_verifications_controller_test.rb
- .ariadna_planning/phases/02-authentication/02-02-SUMMARY.md

All commits verified:
- 10105bc (Task 1): feat(02-02) add email verification mailer, controller, and login gate
- c56dffa (Task 2): feat(02-02) add mailer and email verification integration tests
