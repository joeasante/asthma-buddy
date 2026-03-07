---
status: pending
priority: p1
issue_id: "018"
tags: [code-review, security, csp, authentication]
dependencies: []
---

# CSP Nonce Generator Uses Session ID — Defeats Nonce Security Contract

## Problem Statement

`config/initializers/content_security_policy.rb` sets the CSP nonce generator to `request.session.id.to_s`. A CSP nonce must be single-use per page load and unpredictable. Using the session ID violates both requirements: every page in the same session shares the same nonce, allowing an attacker who observes one nonce to inject scripts with it for the entire session lifetime.

## Findings

**Flagged by:** security-sentinel (F-02), architecture-strategist

**Location:** `config/initializers/content_security_policy.rb` line 23

```ruby
# Current — wrong
config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
```

**Problems:**
1. Session ID is **stable across all requests** in a session — every page load reuses the same nonce value, breaking the single-use guarantee.
2. If an attacker reads one nonce (cached page, leaked referrer, log exposure), they can inject scripts with that nonce for the entire session lifetime (up to 2 weeks per cookie expiry).
3. `session.id.to_s` returns `""` on requests before a session is initialized, producing empty nonces.
4. The nonce generator is currently only in `report_only` mode, but must be fixed before switching to enforcement — changing it after enforcement would cause a behavioral regression in a security-sensitive path.

## Proposed Solutions

### Solution A: SecureRandom nonce (Recommended)
```ruby
config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
```
- **Pros:** Cryptographically random 128-bit nonce per response. Rails' `javascript_importmap_tags` and `csp_meta_tag` helpers use this automatically. No other changes needed.
- **Cons:** None.
- **Effort:** Small (1 line)
- **Risk:** None

### Solution B: SecureRandom with explicit entropy
```ruby
config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.hex(16) }
```
- **Pros:** 32-char hex string instead of base64, slightly easier to read in logs.
- **Cons:** Functionally equivalent to A, no advantage.
- **Effort:** Small
- **Risk:** None

## Recommended Action

Solution A. One-line fix, zero risk, closes a real nonce reuse vulnerability before CSP enforcement is enabled.

## Technical Details

- **Affected file:** `config/initializers/content_security_policy.rb`
- **Line:** 23
- **Dependent work:** Must fix before removing `content_security_policy_report_only = true`

## Acceptance Criteria

- [ ] `content_security_policy_nonce_generator` uses `SecureRandom.base64(16)` or equivalent
- [ ] No `session.id` reference in the nonce generator
- [ ] `rails test` passes
- [ ] Browser dev tools show a different nonce value on each page load

## Work Log

- 2026-03-06: Identified by security-sentinel and architecture-strategist during /ce:review of foundation phase changes
