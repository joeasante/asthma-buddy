---
status: complete
priority: p2
issue_id: "038"
tags: [code-review, csp, security, rails]
dependencies: []
---

# CSP `report_uri` Fires in Development and Test — Adds Noise and Triggers Route in Tests

## Problem Statement

`config/initializers/content_security_policy.rb` sets `policy.report_uri "/csp-violations"` globally (no environment guard). This means every CSP violation from browser extensions, development tooling, or test fixtures will POST to `CspReportsController#create` in development and test environments. In test, this route is live and logs warnings on every violation, creating test noise.

## Findings

**Flagged by:** kieran-rails-reviewer (P2)

**Location:** `config/initializers/content_security_policy.rb`, line 20

```ruby
policy.report_uri "/csp-violations"
```

**Problems in development:**
- Browser extensions (uBlock, dev tools) trigger CSP violations that POST to localhost in development
- These appear as `[CSP Violation]` warnings in the Rails log, obscuring real issues

**Problems in test:**
- System tests or integration tests that trigger a CSP violation (e.g., Selenium injecting scripts) will POST to the real `/csp-violations` route
- Adds unpredictable `[CSP Violation]` log lines to test output
- If CSP is later enforced in test, legitimate test helpers may be blocked

## Proposed Solutions

### Solution A: Guard `report_uri` to production only (Recommended)
```ruby
config.content_security_policy do |policy|
  # ... other directives ...
  policy.report_uri "/csp-violations" if Rails.env.production?
end
```
- **Pros:** Zero impact on development or test. Production behavior unchanged.
- **Effort:** Tiny (1 condition)
- **Risk:** None

### Solution B: Separate CSP config per environment
Move the full CSP initializer block into `config/environments/production.rb`.
- **Pros:** Explicit environment separation.
- **Cons:** More duplication; harder to keep in sync.
- **Effort:** Medium
- **Risk:** Low

## Recommended Action

Solution A — the simplest correct fix.

## Technical Details

- **File:** `config/initializers/content_security_policy.rb`, line 20

## Acceptance Criteria

- [ ] In production: CSP violations POST to `/csp-violations` and are logged
- [ ] In development: no `report_uri` directive in CSP header
- [ ] In test: no `report_uri` directive in CSP header
- [ ] Verified by checking `response.headers["Content-Security-Policy-Report-Only"]` in a controller test

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by kieran-rails-reviewer as P2.
