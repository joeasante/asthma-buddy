---
status: pending
priority: p2
issue_id: 401
tags: [code-review, security, mfa, rate-limiting]
dependencies: []
---

# No rate limit on password re-authentication endpoints

## Problem Statement

`confirm_disable` and `confirm_regenerate_recovery_codes` require password but have no rate limiting. An attacker with a hijacked session could brute-force the password through these endpoints.

## Findings

- **Source:** security-sentinel agent
- **File:** `app/controllers/settings/security_controller.rb`, lines 49-56 and 62-69

## Proposed Solutions

### Option A: Add rate_limit (Recommended)
```ruby
rate_limit to: 5, within: 1.minute, only: %i[confirm_disable confirm_regenerate_recovery_codes], with: -> {
  redirect_to settings_security_path, alert: "Too many attempts. Try again later."
}
```
- **Effort:** Small (3 lines)
- **Risk:** None

## Acceptance Criteria

- [ ] Password re-auth endpoints are rate-limited
- [ ] Rate limit test added

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 27 code review | |
