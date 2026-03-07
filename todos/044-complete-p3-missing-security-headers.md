---
status: complete
priority: p3
issue_id: "044"
tags: [code-review, security, headers, hipaa]
dependencies: []
---

# Missing `Referrer-Policy` and `Permissions-Policy` HTTP Security Headers

## Problem Statement

The app correctly sets HSTS (`force_ssl`), X-Frame-Options, X-Content-Type-Options (Rails defaults), and CSP. However, two additional security headers relevant to a health app are absent: `Referrer-Policy` (URL path leakage to external sites) and `Permissions-Policy` (browser API access control). For a HIPAA-adjacent health app these are meaningful hardening steps.

## Findings

**Flagged by:** security-sentinel (Low — Finding 10)

**Missing headers:**

**`Referrer-Policy`:** Without this, navigating from any page to an external link sends the full URL as `Referer`. For a health app, paths like `/symptom_logs/42` or query strings may encode health context visible in access logs of third-party sites. Recommended value: `strict-origin-when-cross-origin`.

**`Permissions-Policy`:** Without this, browser permissions (camera, microphone, geolocation) are not restricted. If XSS occurs, an injected script could request these APIs without the user being aware they're coming from the health app context. Recommended: explicitly deny access to sensitive APIs.

## Proposed Solutions

### Solution A: Add headers to `config/application.rb` (Recommended)
```ruby
# In Rails.application.configure block or config level:
config.action_dispatch.default_headers.merge!(
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  "Permissions-Policy" => "camera=(), microphone=(), geolocation=(), payment=()"
)
```
- **Pros:** Applied to all responses globally. Single place to manage. Works in all environments.
- **Effort:** Small (2-3 lines)
- **Risk:** None (headers are additive; no functionality change)

### Solution B: Add to `config/environments/production.rb` only
- **Pros:** No dev/test noise.
- **Cons:** Security headers not present in staging/review envs. Prefer Solution A.
- **Effort:** Small

### Solution C: Set via Thruster/reverse proxy
Let Thruster or nginx inject these headers.
- **Pros:** No Rails code change.
- **Cons:** Headers not present in development. Harder to audit.

## Recommended Action

Solution A. These headers are effectively free — zero performance cost, zero functionality impact. Relevant HIPAA-adjacent practice for any app handling health data.

## Technical Details

- **File:** `config/application.rb` (or `config/environments/production.rb`)
- **Reference:** OWASP Secure Headers Project, Rails Security Guide

## Acceptance Criteria

- [ ] `Referrer-Policy: strict-origin-when-cross-origin` present in all responses
- [ ] `Permissions-Policy: camera=(), microphone=(), geolocation=()` present in all responses
- [ ] Headers verified in browser DevTools on production deploy
- [ ] No existing functionality broken (no feature uses camera/mic/geo)

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by security-sentinel as Low/HIPAA-adjacent.
