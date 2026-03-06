---
phase: 02-authentication
plan: 03
subsystem: auth
tags: [persistent-sessions, password-reset, nav-auth, route-protection, system-tests, capybara]

# Dependency graph
requires:
  - phase: 02-authentication
    plan: 02
    provides: Email verification gate, UserMailer, 37 passing tests, verified_user/unverified_user fixtures

provides:
  - Persistent session cookie with 2-week expiry (replaces 20-year permanent cookie)
  - generates_token_for :password_reset with 1-hour expiry on User model
  - PasswordsController using find_by_token_for(:password_reset) for 1-hour token validation
  - PasswordsMailer updated: app-branded subject, generates token explicitly for mailer views
  - Updated passwords views with WCAG labels, proper submit text, "Back to sign in" link
  - Nav conditional auth links: email + Sign out (logged in) / Sign in + Sign up (logged out)
  - Route protection verified: unauthenticated access redirects to login
  - 39 unit/integration tests passing (up from 37): +2 session tests
  - 4 system tests covering complete auth journey end-to-end

affects:
  - All subsequent phases (auth system fully complete, AUTH-01 through AUTH-05 done)

# Tech tracking
tech-stack:
  added: [Capybara system tests, ActiveJob inline adapter for system test email assertions]
  patterns:
    - 2-week session cookie expiry (security: not 20-year permanent, not browser-session-only)
    - generates_token_for :password_reset with 1-hour expiry overrides has_secure_password 15-min default
    - System tests use ActiveJob inline adapter in setup to make deliver_later synchronous
    - click_button vs click_on in system tests to disambiguate form submits from nav links
    - perform_enqueued_jobs pattern NOT used (inline adapter preferred for system tests with threaded server)

key-files:
  created:
    - test/system/authentication_test.rb
  modified:
    - app/controllers/concerns/authentication.rb (cookie expiry: permanent -> 2.weeks.from_now)
    - app/controllers/passwords_controller.rb (find_by_token_for instead of find_by_password_reset_token!)
    - app/mailers/passwords_mailer.rb (branded subject, explicit @token generation)
    - app/models/user.rb (generates_token_for :password_reset, expires_in: 1.hour)
    - app/views/layouts/application.html.erb (conditional nav auth links)
    - app/views/passwords/new.html.erb (WCAG label, proper submit, back link)
    - app/views/passwords/edit.html.erb (WCAG labels, method: :patch, proper submit)
    - app/views/passwords_mailer/reset.html.erb (use @token, branded copy)
    - app/views/passwords_mailer/reset.text.erb (use @token, branded copy)
    - test/controllers/sessions_controller_test.rb (2 new tests: persistent cookie, route protection)

key-decisions:
  - "2-week cookie expiry chosen over permanent (20-year) for security — long enough for convenience, short enough to limit exposure"
  - "generates_token_for :password_reset overrides has_secure_password 15-min default to provide 1-hour expiry as specified"
  - "find_by_token_for(:password_reset) used in controller to align with generates_token_for token generation (tokens are identical under the hood)"
  - "System tests use ActiveJob inline adapter to ensure deliver_later emails land in ActionMailer::Base.deliveries"
  - "click_button used instead of click_on in system tests to avoid ambiguous match when nav links share text with form submit buttons"

# Metrics
duration: ~15min
completed: 2026-03-06
---

# Phase 2 Plan 03: Persistent Sessions, Password Reset, Nav Auth Links, and System Test Summary

**Persistent 2-week session cookie, password reset with 1-hour token, conditional nav auth links, and complete end-to-end system test covering the full auth journey — AUTH-01 through AUTH-05 complete**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-03-06
- **Tasks:** 2 of 2
- **Files modified:** 11

## Accomplishments

- Changed session cookie from `cookies.signed.permanent` (20-year) to `cookies.signed` with `expires: 2.weeks.from_now` — sessions now survive browser close for 2 weeks
- Added `generates_token_for :password_reset, expires_in: 1.hour` to User model, overriding `has_secure_password`'s 15-min default
- Updated PasswordsController to use `find_by_token_for(:password_reset)` (aligns with generates_token_for tokens)
- Updated PasswordsMailer to generate token explicitly and use branded subject "Reset your password — Asthma Buddy"
- Updated passwords view templates: proper WCAG labels (`form.label`), "Send reset link" / "Reset password" submit buttons, "Back to sign in" link
- Updated application layout nav with conditional auth links: shows email + Sign out when authenticated, Sign in + Sign up when not
- Created full system test (`test/system/authentication_test.rb`) with 3 tests covering complete auth journey, nav state when logged out, and nav state when logged in
- All 39 unit/integration tests pass; all 4 system tests pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Persistent sessions, password reset, nav auth links, route protection** - `9aa1c75` (feat)
2. **Task 2: Persistent session tests and full auth system test** - `2077bc7` (feat)

## Files Created/Modified

- `app/controllers/concerns/authentication.rb` - Cookie expiry changed from `permanent` (20-year) to `expires: 2.weeks.from_now`
- `app/controllers/passwords_controller.rb` - Updated `set_user_by_token` to use `find_by_token_for(:password_reset)` (redirect instead of rescue for invalid token)
- `app/mailers/passwords_mailer.rb` - Branded subject, generates `@token` via `generate_token_for(:password_reset)` for views
- `app/models/user.rb` - Added `generates_token_for :password_reset, expires_in: 1.hour do password_salt.last(10) end`
- `app/views/layouts/application.html.erb` - Conditional nav auth links using `authenticated?` helper and `Current.user`
- `app/views/passwords/new.html.erb` - WCAG label, "Send reset link" submit, "Back to sign in" link
- `app/views/passwords/edit.html.erb` - WCAG labels for both fields, "Reset password" submit, `method: :patch`
- `app/views/passwords_mailer/reset.html.erb` - Use `@token` variable, branded copy, 1-hour expiry text
- `app/views/passwords_mailer/reset.text.erb` - Use `@token` variable, branded copy, 1-hour expiry text
- `test/controllers/sessions_controller_test.rb` - +2 tests: persistent cookie check, unauthenticated route protection
- `test/system/authentication_test.rb` - 3 system tests: complete auth journey, nav logged out, nav logged in

## Decisions Made

- **2-week cookie expiry**: `permanent` (20-year) replaced with `expires: 2.weeks.from_now` — long enough for user convenience, avoids indefinite session exposure.
- **generates_token_for for 1-hour reset token**: Rails 8's `has_secure_password` provides `password_reset_token` with 15-min expiry by default. Adding `generates_token_for :password_reset, expires_in: 1.hour` with `password_salt.last(10)` as entropy overrides to 1-hour as specified. The `password_reset_token` method and `find_by_password_reset_token!` are aliases of `generate_token_for`/`find_by_token_for` under the hood — tokens are identical.
- **Inline ActiveJob adapter for system tests**: `deliver_later` enqueues jobs in the Puma server thread. `perform_enqueued_jobs` only flushes the test thread's queue. Setting `ActiveJob::Base.queue_adapter = :inline` in setup makes deliver_later synchronous in the server thread, so emails land in `ActionMailer::Base.deliveries` immediately.
- **click_button over click_on in system tests**: When nav shows a "Sign in" link and the form has a "Sign in" submit button simultaneously, `click_on` raises `Capybara::Ambiguous`. `click_button` correctly targets only `<input type="submit">` and `<button>` elements.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] generates_token_for needed to override has_secure_password's 15-min default**
- **Found during:** Task 1 (verifying password reset token expiry)
- **Issue:** Plan specified 1-hour expiry for password reset tokens. `has_secure_password` built-in provides 15 minutes (900 seconds). Without explicit `generates_token_for :password_reset, expires_in: 1.hour`, the token would expire in 15 minutes, not 1 hour.
- **Fix:** Added `generates_token_for :password_reset, expires_in: 1.hour do password_salt.last(10) end` to User model. Updated PasswordsController to use `find_by_token_for(:password_reset)`. Updated PasswordsMailer to generate token explicitly via `generate_token_for(:password_reset)`.
- **Files modified:** `app/models/user.rb`, `app/controllers/passwords_controller.rb`, `app/mailers/passwords_mailer.rb`
- **Commit:** `9aa1c75`

**2. [Rule 1 - Bug] System test email assertions required inline queue adapter**
- **Found during:** Task 2 (system test execution)
- **Issue:** `deliver_later` enqueues jobs in the Puma server thread. `ActionMailer::Base.deliveries` was empty after form submission because jobs were queued but not executed. `perform_enqueued_jobs` only flushes the test thread's queue, not the server thread's.
- **Fix:** Set `ActiveJob::Base.queue_adapter = :inline` in system test setup, restored to `:test` in teardown. This makes `deliver_later` execute synchronously within the server thread.
- **Files modified:** `test/system/authentication_test.rb`
- **Commit:** `2077bc7`

**3. [Rule 1 - Bug] Ambiguous Capybara element matches for "Sign in" and "Sign up"**
- **Found during:** Task 2 (system test execution)
- **Issue:** When the login page renders, the nav shows "Sign in" link AND the form has a "Sign in" submit button. Similarly, registration page has "Sign up" nav link AND "Sign up" submit. `click_on` matches both, raising `Capybara::Ambiguous`.
- **Fix:** Used `click_button` instead of `click_on` for all form submit actions. `click_button` only matches `<input type="submit">` and `<button>` elements, not links.
- **Files modified:** `test/system/authentication_test.rb`
- **Commit:** `2077bc7`

---

**Total deviations:** 3 auto-fixed (all Rule 1 bugs)
**Impact on plan:** All fixes necessary for correct token expiry and passing system tests. No scope creep.

## AUTH Requirements Completion Status

- **AUTH-01:** User can create account with email and password — COMPLETE (02-01 + 02-02)
- **AUTH-02:** User receives email verification after signup — COMPLETE (02-02)
- **AUTH-03:** User can log in and stay logged in across browser sessions — COMPLETE (persistent 2-week cookie, this plan)
- **AUTH-04:** User can log out from any page — COMPLETE (nav Sign out button, this plan)
- **AUTH-05:** User can reset password via email link — COMPLETE (password reset flow, this plan)

## Next Phase Readiness

- Complete auth system in place: registration, verification, login, persistent sessions, logout, password reset
- Route protection active: unauthenticated visitors redirected to login for all protected routes
- Nav shows correct auth state in all conditions
- 39 unit/integration tests + 4 system tests all green
- Phase 3 (symptom logging) can begin — auth foundation solid

---
*Phase: 02-authentication*
*Completed: 2026-03-06*

## Self-Check: PASSED

All key files verified present:
- app/controllers/concerns/authentication.rb (2-week cookie expiry)
- app/controllers/passwords_controller.rb (find_by_token_for)
- app/mailers/passwords_mailer.rb (branded subject, explicit @token)
- app/models/user.rb (generates_token_for :password_reset 1.hour)
- app/views/layouts/application.html.erb (conditional nav auth links)
- app/views/passwords/new.html.erb (WCAG labels, Send reset link)
- app/views/passwords/edit.html.erb (WCAG labels, Reset password)
- app/views/passwords_mailer/reset.html.erb (@token variable)
- app/views/passwords_mailer/reset.text.erb (@token variable)
- test/controllers/sessions_controller_test.rb (2 new tests)
- test/system/authentication_test.rb (3 system tests)
- .ariadna_planning/phases/02-authentication/02-03-SUMMARY.md

All commits verified:
- 9aa1c75 (Task 1): feat(02-03) persistent sessions, password reset, nav auth links, route protection
- 2077bc7 (Task 2): feat(02-03) add persistent session tests and full auth system test
