---
status: pending
priority: p2
issue_id: "007"
tags: [code-review, security, csp, xss, rails]
dependencies: []
---

# Content Security Policy Entirely Disabled

## Problem Statement

`config/initializers/content_security_policy.rb` is entirely commented out. The layout includes `<%= csp_meta_tag %>` which emits a nonce, but without a configured policy, no `Content-Security-Policy` header is sent and the nonce is meaningless. XSS attacks have no browser-enforced mitigation layer. For a health app collecting symptom and peak flow data, injected scripts could silently exfiltrate PHI. This must be active before Phase 2 introduces authentication sessions and tokens.

## Findings

**Flagged by:** security-sentinel (MEDIUM), architecture-strategist (MEDIUM)

**Location:** `config/initializers/content_security_policy.rb` (entire file commented out)

Importmap-based JS relies on CSP nonce configuration for `<script type="importmap">` blocks. Without CSP, the nonce infrastructure in the layout does nothing.

## Proposed Solutions

### Option A — Activate with restrictive default policy + report-only mode first (Recommended)
Enable `report_only: true` initially to catch violations without blocking, then switch to enforcing.

```ruby
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self, :data
  policy.img_src     :self, :data
  policy.object_src  :none
  policy.script_src  :self
  policy.style_src   :self, :unsafe_inline
  policy.connect_src :self
  policy.base_uri    :self
  policy.form_action :self
  policy.frame_ancestors :none
end

Rails.application.config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
Rails.application.config.content_security_policy_nonce_directives = %w[script-src]
```

**Pros:** Catch violations in development/staging before enforcing in production.
**Effort:** Small–Medium
**Risk:** Low (report-only doesn't break anything)

### Option B — Enable enforcing policy immediately
Skip report-only and go straight to enforcement.

**Pros:** Immediate protection.
**Cons:** May break features until policy is tuned.
**Effort:** Medium
**Risk:** Medium

## Recommended Action

Option A — enable in report-only mode, tune, then enforce before Phase 2 deploys to production.

## Technical Details

**Affected files:**
- `config/initializers/content_security_policy.rb`

**Acceptance Criteria:**
- [ ] CSP initializer active (not entirely commented out)
- [ ] `Content-Security-Policy` or `Content-Security-Policy-Report-Only` header present in responses
- [ ] Nonce generator configured for importmap
- [ ] `bin/rails test` and `bin/rails test:system` pass with policy active

## Work Log

- 2026-03-06: Identified by security-sentinel in Foundation Phase review.
