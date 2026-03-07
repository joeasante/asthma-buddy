---
status: pending
priority: p2
issue_id: "021"
tags: [code-review, security, csp, architecture]
dependencies: [018]
---

# CSP Has Two Gaps: `unsafe_inline` on style-src and No report-uri

## Problem Statement

The activated CSP has two issues that must be resolved before switching from `report_only` to enforcing mode: (1) `style_src :unsafe_inline` broadly permits inline styles with no nonce protection, enabling CSS injection attacks; (2) there is no `report-uri` directive, so violations in `report_only` mode are silently discarded by the browser rather than collected for analysis.

## Findings

**Flagged by:** security-sentinel (F-01, F-03, F-04), multiple agents

**Location:** `config/initializers/content_security_policy.rb`

```ruby
# Gap 1 — line 15
policy.style_src   :self, :unsafe_inline   # No inline styles exist in codebase — remove this

# Gap 2 — missing entirely
# policy.report_uri "/csp-violation-report"  # Violations go nowhere without this
```

**Gap 1 analysis:** A codebase audit finds zero inline `<style>` blocks in `app/views/`. The `unsafe_inline` entry is unnecessary and was likely copied from a template. It enables CSS injection attacks (CSS exfiltration via attribute selectors can leak form values to attacker-controlled URLs) and sets a precedent of weak style policy.

**Gap 2 analysis:** `content_security_policy_report_only = true` sends a header that *asks the browser to report violations* — but with no `report-uri`, the browser has nowhere to send them. The CSP is currently a no-op for both enforcement AND visibility.

## Proposed Solutions

### Solution A: Remove `unsafe_inline`, add self-hosted report endpoint (Recommended)

**Step 1** — `config/initializers/content_security_policy.rb`:
```ruby
policy.style_src   :self              # Remove :unsafe_inline — no inline styles exist
policy.report_uri  "/csp-violations"  # Add report endpoint
```

**Step 2** — `config/routes.rb`:
```ruby
post "/csp-violations", to: "csp_reports#create"
```

**Step 3** — `app/controllers/csp_reports_controller.rb`:
```ruby
class CspReportsController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def create
    Rails.logger.warn "[CSP Violation] #{request.body.read.truncate(500)}"
    head :no_content
  end
end
```

- **Pros:** Removes unnecessary permission; starts collecting real violation data to inform enforcement timing.
- **Effort:** Small
- **Risk:** None

### Solution B: Add nonce to style-src instead of removing `unsafe_inline`

Add `style-src` to `content_security_policy_nonce_directives` and use nonces for any inline styles.
- **Pros:** Allows future inline styles with nonce protection.
- **Cons:** Overkill — there are no inline styles. Complicates Propshaft stylesheet usage.
- **Effort:** Medium
- **Risk:** Low

## Recommended Action

Solution A. The codebase has no inline styles, so `unsafe_inline` serves no purpose. Add the report endpoint first (tiny) so violations become visible before the policy is enforced.

## Technical Details

- **Affected files:** `config/initializers/content_security_policy.rb`, `config/routes.rb`, new `app/controllers/csp_reports_controller.rb`
- **Dependency:** Fix todo 018 (nonce generator) first — the nonce must be correct before violation data is useful

## Acceptance Criteria

- [ ] `policy.style_src` does not include `:unsafe_inline`
- [ ] `policy.report_uri "/csp-violations"` present
- [ ] `POST /csp-violations` route exists and logs the body
- [ ] `skip_before_action :verify_authenticity_token` on the controller
- [ ] Browser dev tools show no CSP violations on home page load
- [ ] `rails test` passes

## Work Log

- 2026-03-06: Identified by security-sentinel and multiple agents during /ce:review of foundation phase changes
