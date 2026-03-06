---
phase: 02-authentication
verified: 2026-03-06T21:41:30Z
status: passed
score: 10/10 must-haves verified | security: 0 critical, 0 high | performance: 0 high
---

# Phase 2: Authentication Verification Report

**Phase Goal:** Users can create accounts, verify their email, log in and stay logged in across sessions, log out from any page, and recover a forgotten password.
**Verified:** 2026-03-06T21:41:30Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth                                                                               | Status     | Evidence                                                                                              |
|----|------------------------------------------------------------------------------------|------------|-------------------------------------------------------------------------------------------------------|
| 1  | A visitor can fill in a signup form with email and password and create an account   | VERIFIED   | `RegistrationsController#new/create` exists and is substantive; form at `app/views/registrations/new.html.erb` |
| 2  | A registered user can log in with correct credentials                               | VERIFIED   | `SessionsController#create` calls `User.authenticate_by`, creates session, redirects to root         |
| 3  | A user who enters wrong credentials sees an error and is not logged in              | VERIFIED   | `SessionsController#create` redirects back with `alert: "Try another email address or password."`    |
| 4  | User emails are unique — duplicate signup is rejected                               | VERIFIED   | `User` model: `validates :email_address, uniqueness: { case_sensitive: false }`                       |
| 5  | After signup, a verification email is sent to the user's address                    | VERIFIED   | `RegistrationsController#create` calls `UserMailer.email_verification(@user).deliver_later`          |
| 6  | Clicking the verification link marks the user as verified                           | VERIFIED   | `EmailVerificationsController#show` sets `email_verified_at: Time.current` via `find_by_token_for`   |
| 7  | An unverified user cannot log in and sees a verification message                   | VERIFIED   | `SessionsController#create` gates on `user.email_verified_at.present?` before starting session       |
| 8  | A logged-in user remains authenticated after closing and reopening the browser      | VERIFIED   | Authentication concern: `cookies.signed[:session_id] = { ..., expires: 2.weeks.from_now }`           |
| 9  | A user can click Sign out from any page and is immediately logged out               | VERIFIED   | Layout nav: `button_to "Sign out", session_path, method: :delete` inside `if authenticated?` block   |
| 10 | A user who forgot their password can request a reset link and set a new password    | VERIFIED   | `PasswordsController` new/create/edit/update; `PasswordsMailer` with `generates_token_for :password_reset, expires_in: 1.hour` |

**Score:** 10/10 truths verified

### Required Artifacts

| Artifact                                                   | Expected                                   | Status     | Details                                                                                            |
|------------------------------------------------------------|---------------------------------------------|------------|-----------------------------------------------------------------------------------------------------|
| `app/models/user.rb`                                       | has_secure_password, email validations      | VERIFIED   | has_secure_password, uniqueness, format, length(8), normalizes, generates_token_for x2              |
| `app/models/session.rb`                                    | Session model belonging to user             | VERIFIED   | `belongs_to :user` present, 3 lines (appropriately minimal)                                        |
| `app/models/current.rb`                                    | CurrentAttributes for session/user access   | VERIFIED   | `attribute :session; delegate :user, to: :session, allow_nil: true`                                |
| `app/controllers/registrations_controller.rb`              | Signup form and user creation               | VERIFIED   | `new` builds User; `create` saves, calls deliver_later, redirects                                  |
| `app/controllers/sessions_controller.rb`                   | Login and logout with email verification gate | VERIFIED | `new/create/destroy` with `authenticate_by`, `email_verified_at` gate, `terminate_session`         |
| `app/controllers/email_verifications_controller.rb`        | Verification token handling                 | VERIFIED   | Handles valid/already-verified/invalid/expired token cases                                          |
| `app/controllers/passwords_controller.rb`                  | Password reset flow                         | VERIFIED   | new/create/edit/update with `find_by_token_for(:password_reset)` and `allow_unauthenticated_access` |
| `app/controllers/concerns/authentication.rb`               | Session cookie auth concern                 | VERIFIED   | `require_authentication`, `start_new_session_for` (2-week cookie), `terminate_session`             |
| `app/controllers/application_controller.rb`                | Global authentication enforcement           | VERIFIED   | `include Authentication` wires `before_action :require_authentication` globally                    |
| `app/mailers/user_mailer.rb`                               | Email verification mailer                   | VERIFIED   | `email_verification(user)` with correct subject and `@verification_url`                            |
| `app/mailers/passwords_mailer.rb`                          | Password reset mailer                       | VERIFIED   | `reset(user)` generates `@token` via `generate_token_for(:password_reset)`                         |
| `app/views/layouts/application.html.erb`                   | Nav with conditional auth links             | VERIFIED   | `if authenticated?` shows email + Sign out button; else shows Sign in + Sign up links              |
| `app/views/registrations/new.html.erb`                     | Signup form                                 | VERIFIED   | Email, password, password_confirmation fields; error display; link to Sign in                      |
| `app/views/sessions/new.html.erb`                          | Login form                                  | VERIFIED   | Email, password fields; links to Forgot password and Sign up                                       |
| `app/views/passwords/new.html.erb`                         | Password reset request form                 | VERIFIED   | Email field, "Send reset link" submit, "Back to sign in" link                                      |
| `app/views/passwords/edit.html.erb`                        | New password form from reset link           | VERIFIED   | Password and password_confirmation fields, "Reset password" submit, `method: :patch`               |
| `app/views/user_mailer/email_verification.html.erb`        | Verification email HTML template            | VERIFIED   | Renders link to `@verification_url`, mentions 24-hour expiry                                       |
| `app/views/user_mailer/email_verification.text.erb`        | Verification email text template            | VERIFIED   | Renders `@verification_url` as plain text                                                          |
| `app/views/passwords_mailer/reset.html.erb`                | Password reset email HTML template          | VERIFIED   | Uses `@token`, generates `edit_password_url(@token)`, 1-hour expiry mention                        |
| `app/views/passwords_mailer/reset.text.erb`                | Password reset email text template          | VERIFIED   | Uses `@token`, generates `edit_password_url(@token)` as plain text                                 |
| `db/migrate/20260306212016_create_users.rb`                | Users table migration                       | VERIFIED   | `email_address` (unique index), `password_digest`, `email_verified_at`                             |
| `db/migrate/20260306212017_create_sessions.rb`             | Sessions table migration                    | VERIFIED   | `t.references :user` (FK + implicit index), `ip_address`, `user_agent`                            |
| `test/fixtures/users.yml`                                  | Test fixtures with password_digest          | VERIFIED   | `verified_user` (email_verified_at set) and `unverified_user` (nil) with BCrypt digests            |
| `test/models/user_test.rb`                                 | User model validation tests                 | VERIFIED   | 8 tests covering presence, uniqueness, case-insensitivity, format, normalization, password length  |
| `test/controllers/registrations_controller_test.rb`        | Registration integration tests              | VERIFIED   | 6 tests covering new form, valid create, duplicate email, short password, mismatch, email enqueue  |
| `test/controllers/sessions_controller_test.rb`             | Session integration tests                   | VERIFIED   | 8 tests covering login, wrong password, unknown email, logout, unverified gate, persistent cookie   |
| `test/controllers/email_verifications_controller_test.rb`  | Verification flow tests                     | VERIFIED   | 4 tests covering valid, already-verified, invalid, and expired tokens                              |
| `test/controllers/passwords_controller_test.rb`            | Password reset integration tests            | VERIFIED   | 7 tests covering new, create (with/without email), edit, invalid token, update, mismatched passwords |
| `test/mailers/user_mailer_test.rb`                         | Mailer tests                                | VERIFIED   | 3 tests covering recipient, subject, URL token in body                                             |
| `test/system/authentication_test.rb`                       | End-to-end system test                      | VERIFIED   | 3 system tests: complete journey, nav logged-out, nav logged-in                                    |

### Key Link Verification

| From                                            | To                                    | Via                                        | Status   | Details                                                                                   |
|-------------------------------------------------|---------------------------------------|--------------------------------------------|----------|-------------------------------------------------------------------------------------------|
| `app/views/registrations/new.html.erb`          | `RegistrationsController#create`      | `form_with model: @user, url: registration_path` | WIRED | Form POSTs to `registration_path`; strong params permit email_address/password/password_confirmation |
| `app/controllers/sessions_controller.rb`        | `User.authenticate_by`                | Authentication lookup                      | WIRED    | `User.authenticate_by(params.permit(:email_address, :password))` on line 9               |
| `app/controllers/concerns/authentication.rb`    | `Current.session`                     | Session cookie lookup                      | WIRED    | `Current.session ||= find_session_by_cookie` — sets and reads `Current.session`           |
| `app/controllers/registrations_controller.rb`   | `UserMailer#email_verification`       | `deliver_later` after user creation        | WIRED    | `UserMailer.email_verification(@user).deliver_later` on line 13                          |
| `app/views/user_mailer/email_verification.html.erb` | `EmailVerificationsController#show` | Verification URL with signed token        | WIRED    | `@verification_url = email_verification_url(token: ...)` produces `/email_verification/:token` URL |
| `app/controllers/sessions_controller.rb`        | `user.email_verified_at`              | Verification check before login            | WIRED    | `if user.email_verified_at.present?` gates session creation on line 10                   |
| `app/views/layouts/application.html.erb`        | `SessionsController#destroy`          | `button_to` with `method: :delete`         | WIRED    | `button_to "Sign out", session_path, method: :delete, class: "btn-sign-out"` on line 26  |
| `app/controllers/application_controller.rb`    | `app/controllers/concerns/authentication.rb` | `include Authentication`            | WIRED    | `include Authentication` on line 5; wires `before_action :require_authentication` globally |
| `app/mailers/passwords_mailer.rb`               | `app/controllers/passwords_controller.rb` | Reset link with signed token           | WIRED    | `@token = user.generate_token_for(:password_reset)`; `edit_password_url(@token)` used in views |

### Requirements Coverage

| Requirement | Status    | Notes                                                                                |
|-------------|-----------|--------------------------------------------------------------------------------------|
| AUTH-01: Account creation with email and password | SATISFIED | RegistrationsController + User model with has_secure_password fully wired         |
| AUTH-02: Email verification after signup | SATISFIED | UserMailer + EmailVerificationsController + deliver_later hook in registrations     |
| AUTH-03: Log in and stay logged in across sessions | SATISFIED | 2-week persistent cookie via `expires: 2.weeks.from_now` in Authentication concern |
| AUTH-04: Log out from any page | SATISFIED | Nav `button_to "Sign out"` with `method: :delete` renders on every page via layout  |
| AUTH-05: Password reset via email link | SATISFIED | PasswordsController + PasswordsMailer + generates_token_for :password_reset (1.hour) |

### Anti-Patterns Found

No anti-patterns found in any key file. No TODOs, FIXMEs, placeholder text, debug statements, empty implementations, or raise NotImplementedError patterns.

### Security Findings

| Check | Name                    | Severity | File | Detail                  |
|-------|-------------------------|----------|------|-------------------------|
| —     | No issues found         | —        | —    | Brakeman: 0 warnings    |

**Security:** 0 findings. Brakeman 8.0.4 scanned 6 controllers, 4 models, 9 templates — clean. Bundle audit: 0 vulnerabilities. Specific checks passed:
- CHECK 1.1a: No SQL string interpolation in `.where()` calls
- CHECK 2.2a: No `params.permit!` mass assignment
- CHECK 2.1: `csrf_meta_tags` present in layout
- CHECK 3.1a: `has_secure_password` used for password storage (BCrypt)
- CHECK 3.2a: No unscoped `User.find(params[:id])` — token-based lookups via `find_by_token_for` only
- httponly + same_site: :lax flags set on session cookie

### Performance Findings

| Check | Name              | Severity | File | Detail               |
|-------|-------------------|----------|------|----------------------|
| —     | No issues found   | —        | —    | —                    |

**Performance:** 0 findings. All mailer calls use `deliver_later` (async via Solid Queue). No N+1 patterns. Sessions table FK created via `t.references` which Rails auto-indexes.

### Human Verification Required

The following behaviors cannot be fully verified programmatically and require a running application:

#### 1. Email Delivery in Development

**Test:** Sign up with a real email address in development mode, check that a verification email is received.
**Expected:** Email arrives with a working verification link (token embedded in path `/email_verification/:token`).
**Why human:** `deliver_later` goes through Solid Queue in development — requires the worker to be running and Action Mailer delivery method to be configured for real dispatch.

#### 2. Persistent Session Across Browser Close

**Test:** Log in, close the browser entirely (not just the tab), reopen the browser, and navigate to the application.
**Expected:** User is still logged in without being asked for credentials.
**Why human:** Cookie persistence across browser restart is a browser behavior that can't be verified with integration tests (which don't model browser close).

#### 3. Navigation Visual State

**Test:** Log in and observe the navigation; log out and observe again.
**Expected:** When logged in, nav shows the user's email address and a "Sign out" button. When logged out, nav shows "Sign in" and "Sign up" links.
**Why human:** Visual rendering and correct conditional display requires a running browser.

---

## Gaps Summary

No gaps found. All 10 observable truths are verified. All 30 artifacts exist and are substantive. All 9 key links are wired. AUTH-01 through AUTH-05 are fully satisfied. Brakeman and bundle audit are clean.

---

_Verified: 2026-03-06T21:41:30Z_
_Verifier: Claude (ariadna-verifier)_
