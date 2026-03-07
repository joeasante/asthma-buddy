---
status: pending
priority: p2
issue_id: "010"
tags: [code-review, rails, architecture, phase-2]
dependencies: []
---

# Mailer Host Placeholder `example.com` Must Be Replaced Before Phase 2

## Problem Statement

`config/environments/production.rb` has `config.action_mailer.default_url_options = { host: "example.com" }`. Phase 2 adds authentication, which typically includes password reset emails and/or confirmation emails. If this placeholder is not replaced before Phase 2 deploys, all generated email URLs (password reset links, confirmation links) will point to `example.com` — rendering them broken and potentially leaking token information.

## Findings

**Flagged by:** architecture-strategist

**Location:** `config/environments/production.rb` line 61

```ruby
config.action_mailer.default_url_options = { host: "example.com" }
```

## Proposed Solutions

### Option A — Use `ENV.fetch("APP_HOST")` (Recommended)
```ruby
config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST") }
```

Pair with todo #006 (host header protection) using the same `APP_HOST` environment variable.

**Effort:** Trivial
**Risk:** None (requires `APP_HOST` to be set in production environment and Kamal secrets)

### Option B — Hardcode the real domain
```ruby
config.action_mailer.default_url_options = { host: "your-domain.com" }
```

**Effort:** Trivial
**Risk:** Low (domain must be known before this change)

## Recommended Action

Option A — `ENV.fetch("APP_HOST")` for consistency with host header allowlist config.

## Technical Details

**Affected files:**
- `config/environments/production.rb`
- `.kamal/secrets` (add `APP_HOST=your-domain.com`)

**Acceptance Criteria:**
- [ ] `config.action_mailer.default_url_options` references `APP_HOST` env var or hardcoded real domain
- [ ] Password reset / confirmation email URLs in Phase 2 point to correct domain

## Work Log

- 2026-03-06: Identified by architecture-strategist. Must resolve before Phase 2 email flows deploy.
