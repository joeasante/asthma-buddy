---
status: pending
priority: p2
issue_id: "006"
tags: [code-review, security, rails, production]
dependencies: []
---

# Host Header Protection Not Configured

## Problem Statement

`config/environments/production.rb` has `config.hosts` commented out. Without an allowlist of permitted `Host` header values, the app is vulnerable to DNS rebinding attacks and Host header injection. This becomes critical in Phase 2 when authentication introduces password reset emails — an attacker manipulating the `Host` header can cause password reset links to point to attacker-controlled domains.

## Findings

**Flagged by:** security-sentinel (MEDIUM), architecture-strategist (MEDIUM)

**Location:** `config/environments/production.rb` lines 83–89

```ruby
# config.hosts = [
#   "example.com",
#   /.*\.example\.com/
# ]
```

**Attack scenario (Phase 2+):** Attacker sends `POST /password_resets` with `Host: attacker.com`. Rails generates a reset link using `attacker.com` as the host. Email is sent to victim. Victim clicks link to `attacker.com`, sending the reset token to the attacker.

## Proposed Solutions

### Option A — Configure `config.hosts` with actual domain (Recommended)
```ruby
config.hosts = [
  "your-app-domain.com",
  /.*\.your-app-domain\.com/
]
```

**Pros:** Blocks the attack at the Rails level; straightforward.
**Effort:** Small
**Risk:** None

### Option B — Use environment variable for domain
```ruby
config.hosts = [ENV.fetch("APP_HOST")]
```

**Pros:** Configurable without code changes; same domain drives mailer, host allowlist, and Kamal proxy.
**Effort:** Small
**Risk:** None

## Recommended Action

Option B — `ENV.fetch("APP_HOST")` for consistency with the mailer host change (todo #010).

## Technical Details

**Affected files:**
- `config/environments/production.rb`

**Acceptance Criteria:**
- [ ] `config.hosts` set with production domain
- [ ] Requests with mismatched `Host` header receive 403 in production
- [ ] `APP_HOST` environment variable documented in deployment guide

## Work Log

- 2026-03-06: Identified by security-sentinel. Must resolve before Phase 2 authentication launch.
