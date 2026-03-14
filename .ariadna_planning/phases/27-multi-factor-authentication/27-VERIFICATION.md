---
phase: 27-multi-factor-authentication
verified: 2026-03-14T21:00:00Z
status: passed
score: 5/5 must-haves verified | security: 0 critical, 0 high | performance: 0 high
---

# Phase 27: Multi-Factor Authentication Verification Report

**Phase Goal:** Users can protect their accounts with TOTP-based two-factor authentication, including setup via QR code, mandatory TOTP entry at login, recovery codes for emergency access, and the ability to disable MFA.
**Verified:** 2026-03-14T21:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can navigate to security settings, initiate MFA setup, scan QR code, enter verification code, and enable MFA | VERIFIED | Settings::SecurityController has `setup` (generates QR via ROTP/RQRCode), `confirm_setup` (verifies TOTP code, calls `enable_mfa!`). Views exist: setup.html.erb with QR SVG + manual key + verification form. Settings page has Security nav card linking to `settings_security_path`. 14 controller tests pass including full setup flow. |
| 2 | MFA-enabled user is held in pending MFA state after password login, must enter valid TOTP before accessing authenticated pages | VERIFIED | SessionsController#create checks `user.otp_required_for_login?` BEFORE `start_new_session_for`, sets `session[:pending_mfa_user_id]` and redirects to `new_mfa_challenge_path`. MfaChallengeController verifies TOTP via `user.verify_otp`, only then calls `start_new_session_for`. 5-minute expiry enforced via `require_pending_mfa` before_action. 8 controller tests + 5 sessions tests pass. |
| 3 | Upon enabling MFA, user sees 10 one-time recovery codes and can download as text file; each code usable exactly once | VERIFIED | `enable_mfa!` generates 10 codes via `SecureRandom.hex(5)`. recovery_codes.html.erb displays codes in grid. `download_recovery_codes` action sends text file with `send_data`. `verify_recovery_code` consumes code on use (deletes from array, saves). Tests verify single-use: "already-used recovery code fails" test passes. Download returns text/plain with "Asthma Buddy Recovery Codes". |
| 4 | User can disable MFA from security settings after re-entering password; subsequent logins skip TOTP | VERIFIED | `disable` action renders password form, `confirm_disable` calls `Current.user.authenticate(params[:password])` then `disable_mfa!`. `disable_mfa!` clears all 4 MFA fields (otp_secret, otp_required_for_login, otp_recovery_codes, last_otp_at). Tests verify wrong password rejected (422), correct password disables. Model test confirms `otp_required_for_login?` returns false after disable. |
| 5 | TOTP secrets and recovery codes are stored encrypted at rest | VERIFIED | User model declares `encrypts :otp_secret, deterministic: false` and `encrypts :otp_recovery_codes, deterministic: false`. Migration uses `:text` columns (accommodates encrypted payload). Model test "otp_secret is encrypted at rest" reads raw DB value and asserts it differs from plaintext. AR Encryption keys configured in credentials. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `app/models/user.rb` | MFA methods + encryption declarations | VERIFIED | enable_mfa!, disable_mfa!, verify_otp, verify_recovery_code, regenerate_recovery_codes!, recovery_codes, recovery_codes_remaining, otp_required_for_login? all present. `encrypts :otp_secret` and `encrypts :otp_recovery_codes` declared. |
| `db/migrate/20260314201031_add_mfa_columns_to_users.rb` | MFA columns migration | VERIFIED | otp_secret (text), otp_required_for_login (boolean, default false), otp_recovery_codes (text), last_otp_at (datetime). All present in schema.rb. |
| `app/controllers/mfa_challenge_controller.rb` | Post-login TOTP verification | VERIFIED | 78 lines. skip_pundit, allow_unauthenticated_access, rate_limit 5/min, require_pending_mfa with 5-min expiry, verify_otp + verify_recovery_code, complete_mfa_login helper. |
| `app/controllers/settings/security_controller.rb` | MFA setup/disable/recovery lifecycle | VERIFIED | 80 lines. show, setup (QR), confirm_setup, recovery_codes, download_recovery_codes, disable, confirm_disable, regenerate_recovery_codes, confirm_regenerate_recovery_codes. All Pundit-authorized. |
| `app/controllers/sessions_controller.rb` | Pending MFA redirect | VERIFIED | Lines 45-52: checks `otp_required_for_login?` before `start_new_session_for`, sets pending session state, redirects to MFA challenge. Lines 14-15, 19-20: clears stale pending state. |
| `app/helpers/mfa_helper.rb` | QR code SVG generation | VERIFIED | `mfa_qr_svg` method using RQRCode with SVG output. |
| `config/routes.rb` | MFA challenge + security settings routes | VERIFIED | `resource :mfa_challenge` with controller option. `resource :security` nested under settings with setup, confirm_setup, recovery_codes, download_recovery_codes, disable, confirm_disable, regenerate_recovery_codes, confirm_regenerate_recovery_codes. |
| `app/views/mfa_challenge/new.html.erb` | TOTP code entry form | VERIFIED | 33 lines. Auth-card pattern, OTP input with numeric inputmode, recovery code hint, back-to-login link. |
| `app/views/settings/security/show.html.erb` | Security settings with MFA status | VERIFIED | 65 lines. Page header, conditional enabled/disabled display, setup/disable/recovery links. |
| `app/views/settings/security/setup.html.erb` | QR code setup page | VERIFIED | 79 lines. Step-by-step instructions, QR SVG with hardcoded white background, manual key display, verification form. |
| `app/views/settings/security/recovery_codes.html.erb` | Recovery codes display + download | VERIFIED | 57 lines. Warning card, code grid, download button (POST form), done link. |
| `app/views/settings/security/disable.html.erb` | Password re-auth for MFA disable | VERIFIED | 55 lines. Warning card (danger variant), password form, destructive submit button. |
| `app/views/settings/security/regenerate_recovery_codes.html.erb` | Password re-auth for code regeneration | EXISTS | Not read but confirmed via glob. |
| `app/views/settings/show.html.erb` | Security nav card | VERIFIED | Line 57-68: Security card with shield icon, MFA status badge, correct link to settings_security_path. |
| `Gemfile` | rotp and rqrcode gems | VERIFIED | `gem "rotp", "~> 6.3"` and `gem "rqrcode", "~> 3.2"`. |
| `test/models/user_test.rb` | MFA model tests | VERIFIED | 11 MFA-specific tests covering all methods + encryption at rest. |
| `test/controllers/mfa_challenge_controller_test.rb` | MFA challenge tests | VERIFIED | 8 tests: pending state, valid TOTP, invalid code, recovery code, consumed recovery code, expiry, no pending state. |
| `test/controllers/settings/security_controller_test.rb` | Security settings tests | VERIFIED | 14 tests: status display, setup flow, recovery codes, disable, regenerate. |
| `test/controllers/sessions_controller_test.rb` | MFA redirect tests | VERIFIED | 5 MFA-specific tests added: redirect to challenge, pending state set, no session cookie, non-MFA unaffected, stale state cleared. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| sessions_controller.rb | mfa_challenge_controller.rb | `redirect_to new_mfa_challenge_path` | WIRED | Line 49: redirects MFA users to challenge after setting pending session state |
| mfa_challenge_controller.rb | user.rb | `verify_otp` and `verify_recovery_code` | WIRED | Lines 27, 33: calls both verification methods on user found via pending session |
| settings/security_controller.rb | user.rb | `enable_mfa!` and `disable_mfa!` | WIRED | Line 23: `Current.user.enable_mfa!(secret)`, Line 55: `Current.user.disable_mfa!` |
| settings/show.html.erb | security_controller.rb | `settings_security_path` | WIRED | Line 57: Security nav card links to settings_security_path |
| routes.rb | mfa_challenge_controller.rb | resource route | WIRED | `resource :mfa_challenge, controller: "mfa_challenge"` resolves correctly |
| routes.rb | settings/security_controller.rb | nested resource route | WIRED | `resource :security, controller: "security"` with all custom actions |

### Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| MFA-01: Setup via QR code | SATISFIED | None |
| MFA-02: Mandatory TOTP at login | SATISFIED | None |
| MFA-03: Recovery codes (10, downloadable, single-use) | SATISFIED | None |
| MFA-04: Disable MFA with password re-auth | SATISFIED | None |
| MFA-05: Encrypted secrets at rest | SATISFIED | None |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | — | — | — |

No TODO/FIXME/PLACEHOLDER/debug statements found in any MFA file.

### Security Findings

| Check | Name | Severity | File | Line | Detail |
|-------|------|----------|------|------|--------|
| 2.2a | Strong parameters | OK | mfa_challenge_controller.rb | 27 | `params[:otp_code]` is a single scalar passed to verify_otp (string comparison) — no mass assignment risk |
| 3.2a | Scoped resource lookup | OK | mfa_challenge_controller.rb | 19 | User found via `session[:pending_mfa_user_id]` (server-side session, not client params) — no IDOR |
| 1.2 | XSS | OK | setup.html.erb | 38 | `@qr_svg.html_safe` — SVG generated by RQRCode library, not user input |
| 2.1 | CSRF | OK | All controllers | — | All state-changing actions use POST with Rails CSRF protection |
| 3.1 | Rate limiting | OK | mfa_challenge_controller.rb | 6 | Rate limited to 5/min on create action |

**Security:** 0 findings (0 critical, 0 high, 0 medium)

### Performance Findings

No performance concerns identified. MFA operations are lightweight (TOTP verification, single DB updates). No N+1 queries, no unbatched iterations.

**Performance:** 0 findings (0 high, 0 medium, 0 low)

### Human Verification Required

### 1. QR Code Scanning

**Test:** Navigate to Settings > Security > Enable, scan the QR code with Google Authenticator or Authy, enter the code, verify MFA enables successfully.
**Expected:** QR code renders clearly, authenticator app reads it correctly, 6-digit code verifies on first try.
**Why human:** Cannot verify QR code visual clarity or authenticator app compatibility programmatically.

### 2. Full Login Flow with MFA

**Test:** Log out, log back in with password, verify MFA challenge page appears, enter TOTP code from authenticator app.
**Expected:** Smooth redirect to MFA challenge, code entry works, user lands on dashboard after verification.
**Why human:** Cannot verify redirect timing, visual flow, or real TOTP code entry experience programmatically.

### 3. Recovery Code Download

**Test:** After enabling MFA, click "Download Codes" button on recovery codes page.
**Expected:** Browser downloads a .txt file named "asthma-buddy-recovery-codes.txt" with 10 formatted codes.
**Why human:** Cannot verify browser download behavior programmatically.

### 4. Mobile Responsiveness

**Test:** Complete MFA setup and login challenge flows on a mobile device.
**Expected:** QR code fits screen, code input is easy to use, all buttons accessible.
**Why human:** Cannot verify mobile visual layout and touch interaction programmatically.

### Gaps Summary

No gaps found. All 5 success criteria are satisfied:

1. MFA setup flow is fully wired: Settings > Security > Enable > QR code > verify code > recovery codes shown.
2. Pending MFA state prevents access before TOTP verification. SessionsController intercepts BEFORE `start_new_session_for`. 5-minute expiry enforced.
3. 10 recovery codes generated, displayed in grid, downloadable as text file, each consumable exactly once.
4. Disable requires password re-authentication, clears all MFA fields, subsequent logins skip TOTP.
5. AR Encryption with `encrypts :otp_secret` and `encrypts :otp_recovery_codes` — verified by model test reading raw DB.

72 tests pass (11 model + 8 challenge + 14 security + 5 sessions MFA + 34 existing), 0 failures, 0 errors.

---

_Verified: 2026-03-14T21:00:00Z_
_Verifier: Claude (ariadna-verifier)_
