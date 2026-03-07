---
status: pending
priority: p2
issue_id: "049"
tags: [code-review, security, csp, xss]
dependencies: []
---

# CSP `report_only: true` Is Unconditional — Policy Never Enforces in Any Environment

## Problem Statement

`config.content_security_policy_report_only = true` is set without any environment guard, meaning the CSP is in report-only mode everywhere — development, test, and production. The browser observes violations but never blocks them. XSS payloads are unimpeded by the CSP in production.

## Findings

**Flagged by:** security-sentinel (MEDIUM-01), kieran-rails-reviewer (HIGH), architecture-strategist

**Location:** `config/initializers/content_security_policy.rb:30`

```ruby
config.content_security_policy_report_only = true  # unconditional
```

The policy itself is well-constructed (no `unsafe-inline`, correct `frame-ancestors: none`, `form-action: self`, nonces on scripts). The only problem is enforcement is disabled globally.

**Secondary issue:** CSP violations are also invisible in development because `report_uri "/csp-violations"` is gated to production only:

```ruby
policy.report_uri "/csp-violations" if Rails.env.production?
```

This means developers never see CSP violations locally, so integration bugs (e.g., from Lexxy) are only discovered in production.

## Proposed Solutions

### Solution A: Enable enforcement in production after reviewing violation logs (Recommended)

```ruby
# config/initializers/content_security_policy.rb
config.content_security_policy_report_only = !Rails.env.production?

# And enable report_uri in development too:
policy.report_uri "/csp-violations"  # remove the `if Rails.env.production?` guard
```

This enforces the CSP in production (the only place it matters for security) while keeping report-only in development for easier debugging.

- **Pros:** Maximally secure in production. Violations visible in development logs.
- **Effort:** Small — two lines changed
- **Risk:** Low if violation logs show zero violations; check logs first

### Solution B: Enforce everywhere

```ruby
config.content_security_policy_report_only = false
```
- **Pros:** Consistent behavior everywhere
- **Cons:** May break development workflows if any inline styles/scripts are present
- **Risk:** Medium — test thoroughly in development first

### Solution C: Stay report-only until violation log review is complete

Keep current config, but set a deadline to switch. Add a comment with a date.
- **Pros:** Zero risk
- **Cons:** CSP provides zero security value until switched
- **Risk:** Will be forgotten

## Acceptance Criteria

- [ ] CSP is enforced (not report-only) in production
- [ ] Violation reports are visible in development logs for debugging
- [ ] No legitimate app functionality broken by CSP enforcement (verify with browser tests)
- [ ] Nonce is correctly applied to all `<script>` tags in the layout

## Work Log

- 2026-03-07: Created from multi-agent code review. Security-sentinel MEDIUM-01, kieran-rails-reviewer HIGH.
