---
title: "Phase 27 MFA code review — 10 findings fixed across security, architecture, and code quality"
date: 2026-03-14
category: security-issues
tags:
  - mfa
  - totp
  - code-review
  - phase-27
  - multi-agent-review
  - security-hardening
severity: P1-P3
modules:
  - app/models/user.rb
  - app/controllers/mfa_challenge_controller.rb
  - app/controllers/sessions_controller.rb
  - app/controllers/settings/security_controller.rb
  - app/controllers/concerns/authentication.rb
  - app/views/mfa_challenge
  - app/views/settings/security
  - db/migrate
symptoms:
  - "Recovery codes silently truncated by maxlength=6 on challenge input"
  - "Sign-in tracking executed twice per MFA-authenticated login"
  - "Timing attack possible on recovery code comparison via non-constant-time equality"
  - "MFA disable and recovery_codes actions accessible to users without MFA enabled"
  - "Password re-auth endpoints (confirm_disable, confirm_regenerate) lacked rate limiting"
  - "Recovery code entropy at 40 bits (hex 5) below 64-bit industry standard"
  - "TOTP secret regenerated on every setup page refresh, invalidating previously scanned QR"
  - "Two separate UPDATE queries per login instead of one batched update"
root_cause: "Initial MFA implementation prioritized feature completeness over defensive coding; security edge cases (timing attacks, input constraints, access guards, entropy) and DRY violations were not caught until multi-agent review"
---

# Phase 27 MFA Code Review — 10 Findings Fixed

After implementing TOTP-based MFA (Phase 27), a multi-agent code review with 7 specialized agents (kieran-rails-reviewer, security-sentinel, performance-oracle, architecture-strategist, pattern-recognition-specialist, code-simplicity-reviewer, schema-drift-detector) identified 10 issues. All were fixed in a single pass with 661 tests passing.

## P1 — Critical

### 1. maxlength truncation on shared input field

**Root cause:** The MFA challenge form input had `maxlength: 6`, matching TOTP code length. Recovery codes are 17 chars (16 hex + hyphen). The browser silently truncated recovery code input, causing every recovery code attempt to fail.

**File:** `app/views/mfa_challenge/new.html.erb`

**Fix:** Remove `maxlength` entirely. The server handles both code types without a client-side length constraint.

```erb
<%# Before %>
<%= form.text_field :otp_code, maxlength: 6, inputmode: "numeric" %>

<%# After — no maxlength, pattern accepts alphanumeric + hyphens %>
<%= form.text_field :otp_code, inputmode: "numeric", pattern: "[0-9a-zA-Z-]*" %>
```

**Key takeaway:** When an input accepts multiple token types of different lengths, remove maxlength or set it to the longest type.

## P2 — Important

### 2. Duplicated sign-in tracking logic

**Root cause:** Both `SessionsController#create` and `MfaChallengeController#complete_mfa_login` independently implemented sign-in tracking with copy-pasted code. Flagged by 5 of 7 review agents.

**Fix:** Extract `complete_sign_in(user)` into the shared `Authentication` concern. Also consolidates two UPDATE statements into one.

```ruby
# app/controllers/concerns/authentication.rb
def complete_sign_in(user)
  start_new_session_for user
  session[:last_seen_at] = Time.current
  User.where(id: user.id).update_all(
    ["last_sign_in_at = ?, sign_in_count = sign_in_count + 1", Time.current]
  )
end
```

### 3. Timing attack on recovery code verification

**Root cause:** `codes.index(normalized)` uses Ruby `==` which short-circuits on the first mismatched byte.

**Fix:** Use constant-time comparison.

```ruby
# Before
index = codes.index(normalized)

# After
index = codes.index { |c| ActiveSupport::SecurityUtils.secure_compare(c.delete("-"), normalized) }
```

### 4. Unguarded MFA-only actions

**Root cause:** `Settings::SecurityController` had no guards preventing users without MFA from hitting disable/recovery_codes actions, or users with MFA from hitting setup.

**Fix:** Paired `before_action` guards.

```ruby
before_action :require_mfa_disabled, only: %i[setup confirm_setup]
before_action :require_mfa_enabled, only: %i[recovery_codes download_recovery_codes
  disable confirm_disable regenerate_recovery_codes confirm_regenerate_recovery_codes]
```

### 5. Missing rate limit on password re-authentication

**Root cause:** Disable-MFA and regenerate-recovery-codes flows require password but had no rate limiting.

**Fix:** Apply Rails 8 `rate_limit`.

```ruby
rate_limit to: 5, within: 1.minute, only: %i[confirm_disable confirm_regenerate_recovery_codes]
```

### 6. Low recovery code entropy

**Root cause:** `SecureRandom.hex(5)` = 40 bits. Industry standard is 64+ bits.

**Fix:** Increase to `hex(8)` with hyphen separator for readability.

```ruby
# Before: "a1b2c3d4e5" (40 bits)
SecureRandom.hex(5)

# After: "a1b2c3d4-e5f6a7b8" (64 bits)
SecureRandom.hex(8).scan(/.{8}/).join("-")
```

## P3 — Minor

**7. Secret regeneration on refresh:** Changed `=` to `||=` for `session[:pending_otp_secret]` so refreshing the setup page preserves the QR code.

**8. Two UPDATE statements per login:** Consolidated into single `update_all` within `complete_sign_in` (covered by fix 2).

**9. Missing frozen_string_literal:** Added magic comment to migration file.

**10. Trivial wrapper method:** Removed private `recovery_codes_array`, inlined into public `recovery_codes`.

## Prevention Strategies

### General Principles

1. **Security primitives deserve paranoid defaults.** Any code that touches authentication, secrets, or tokens should default to the most defensive option. Always use `secure_compare` for secrets. Always rate-limit endpoints that accept secrets. Always check entropy against NIST/OWASP standards.

2. **One fact, one place.** Before copying logic between controllers, extract it into a concern. Before adding a helper, ask whether it does anything the caller cannot trivially do inline.

3. **Inputs must match the full domain.** When a single input accepts multiple token formats, constraints must accommodate the longest. A `maxlength` of 6 silently prevents 17-character recovery code entry.

4. **Convention consistency is not optional.** Every action requiring a precondition needs a `before_action` guard. Never rely on the UI hiding the link — the route is the contract.

### Pre-Implementation Checklist for Security Features

- [ ] All token comparisons use constant-time functions (`secure_compare`)
- [ ] Generated secrets meet minimum entropy (64+ bits for recovery codes)
- [ ] Every endpoint accepting a secret has rate limiting
- [ ] Every action assuming a precondition has a `before_action` guard
- [ ] **When an input accepts multiple token types, remove maxlength or set it to the longest type**
- [ ] GET actions that generate ephemeral state are idempotent (`||=`, not `=`)
- [ ] No duplicated controller logic — shared behavior lives in concerns
- [ ] No redundant database writes — combine into single UPDATE where possible
- [ ] All project conventions applied uniformly (frozen_string_literal, naming)
- [ ] Run `bin/brakeman` and full test suite before PR

## Related Documentation

- [PR #17 comprehensive code review — 28 fixes](../code-quality/pr17-comprehensive-code-review-28-fixes.md) — Rate limiting patterns, TOCTOU races, atomic sign-in counter, DRY violations
- [Session termination vs reset on account deletion](./terminate-session-vs-reset-session-account-deletion.md) — Session handling security
- [Authorization scope bypass via wrong parent association](./authorization-scope-bypass-via-wrong-parent-association.md) — Nested resource scoping patterns
