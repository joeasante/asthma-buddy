---
title: "Phase 28 REST API — Code Review Fixes"
problem_type: code_quality
modules: [api_v1, authentication, rate_limiting, api_keys, admin_ui]
tags: [code-review, security, sql-injection, arel, rack-attack, stimulus, cache-headers, bearer-token, admin-styling]
severity: mixed
date_solved: 2026-03-14
---

# Phase 28 REST API — Code Review Fixes

## Problem

After implementing Phase 28 (REST API with token authentication, rate limiting, and API key management), a multi-agent code review identified 10 issues across security, performance, architecture, and code quality. Additionally, the admin pages under Settings lacked design system compliance.

## Symptoms

- SQL string interpolation in date filter (`"#{date_column}"`) — injection vector
- Bearer token regex accepted any characters (`\S+`) instead of hex-only
- API responses returned with default caching headers — sensitive health data could be cached
- API key plaintext exposed via flash cookie during redirect (visible in browser tools)
- `def self.authenticate_by_api_key` inside `included do` block — wrong ActiveSupport::Concern pattern
- Unnecessary `.includes(:dose_logs)` eager loading in medications endpoint
- Rate limiting test hitting non-existent `/api/v1/health` route
- Unauthenticated API requests had no rate limit
- Admin dashboard and users pages used wrong CSS variables and lacked mobile support
- Badge classes referenced but never defined (`.badge--success`, `.badge--danger`, `.badge--member`)

## Root Cause Analysis

### 1. SQL Injection via String Interpolation (P1 Critical)
The `date_filter` method in `Api::V1::BaseController` used `"#{date_column}"` to build SQL WHERE clauses. While the column name came from internal code (not user input), this pattern is unsafe by convention and would become exploitable if a caller ever passed user-controlled data.

**Fix:** Replaced with `scope.arel_table[date_column]` for safe column references. Added `InvalidDateParam` exception with `rescue_from` for invalid date format handling.

### 2. Overly Permissive Bearer Token Regex (P1 Critical)
The `extract_bearer_token` method accepted `/\ABearer\s+(\S+)\z/` — matching any non-whitespace characters. API keys are 64-character hex strings; the regex should enforce this.

**Fix:** Tightened to `/\ABearer\s+([a-f0-9]{64})\z/` in both `base_controller.rb` and `rack_attack.rb`.

### 3. Missing Cache-Control Headers (P1 Critical)
API responses for health data (symptom logs, peak flow readings, medications) used default caching behavior. Proxies or browsers could cache sensitive PHI.

**Fix:** Added `before_action :set_cache_headers` in `BaseController`:
```ruby
def set_cache_headers
  response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, private"
  response.headers["Pragma"] = "no-cache"
end
```

### 4. API Key Plaintext in Flash Cookie (P2 Important)
After generating an API key, `create` action used `redirect_to` with `flash[:api_key]` carrying the plaintext token. Flash is stored in cookies — the secret was persisted client-side.

**Fix:** Changed to `render :show` with `@plaintext_key` instance variable. Added Stimulus `clipboard_controller.js` for copy-to-clipboard functionality.

### 5. Wrong ActiveSupport::Concern Pattern (P2 Important)
`ApiAuthenticatable` concern defined `def self.authenticate_by_api_key` inside `included do` — this creates a method on the concern module itself, not on the including class.

**Fix:** Used `class_methods do` block:
```ruby
class_methods do
  def authenticate_by_api_key(token)
    return nil if token.blank?
    digest = Digest::SHA256.hexdigest(token)
    find_by(api_key_digest: digest)
  end
end
```

### 6. Unnecessary Eager Loading (P2 Important)
`MedicationsController#index` used `.includes(:dose_logs)` but the JSON response only serialized medication attributes — dose logs were loaded then discarded.

**Fix:** Removed `.includes(:dose_logs)`.

### 7. No Unauthenticated Rate Limit (P2 Important)
Rack::Attack only throttled authenticated API requests. Unauthenticated requests (probing, scanning) had no limit.

**Fix:** Added second throttle rule keyed on IP for requests without a valid Bearer token:
```ruby
throttle("api/v1/unauthenticated", limit: 10, period: 1.minute) do |req|
  if req.path.start_with?("/api/v1/")
    token = req.env["HTTP_AUTHORIZATION"]&.match(/\ABearer\s+([a-f0-9]{64})\z/)&.[](1)
    req.ip unless token.present?
  end
end
```

### 8. Test Hitting Non-Existent Route (P3)
Rate limiting tests used `/api/v1/health` which doesn't exist. Tests passed because Rack::Attack runs before routing, but the 404 masked intent.

**Fix:** Changed all test requests to `/api/v1/symptom_logs`.

### 9-10. Admin UI Design System Non-Compliance
Admin dashboard and users pages used inline styles with wrong CSS variable names (`--spacing-*` instead of `--space-*`), lacked the standard `.section-card` / `.page-header` patterns, had no mobile breakpoints, and referenced undefined badge classes.

**Fix:** Complete rewrite of both admin views and `admin.css`:
- Added breadcrumb eyebrow navigation (Settings > Admin > Users)
- Proper `.section-card-header` / `.section-card-body` structure
- Defined `.badge--success`, `.badge--danger`, `.badge--member` with design system colors
- Added `.admin-table-wrap` for mobile horizontal scroll
- Mobile breakpoints for stat cards and site settings layout
- Added `.btn-small` as global compact button variant

## Prevention Strategies

1. **SQL injection in internal code**: Always use Arel (`scope.arel_table[column]`) or parameterized queries, even for "trusted" inputs. String interpolation in SQL should be a code review red flag regardless of source.

2. **Token format validation**: Bearer tokens should match their known format exactly. Define token format as a constant and reuse across controller extraction and Rack::Attack rules.

3. **Cache-Control for health data**: Any controller serving PHI/PII must set `no-store` cache headers. Consider a shared concern or base controller `before_action` so new endpoints inherit it automatically.

4. **Secrets in flash cookies**: Never put secrets (API keys, tokens, passwords) in flash messages. Use `render` with instance variables or one-time-use database records.

5. **ActiveSupport::Concern conventions**: Use `class_methods do` for class methods, `included do` for callbacks/validations/scopes. `def self.` inside `included` defines methods on the wrong receiver.

6. **Eager loading audit**: Only `.includes` associations that are actually referenced in the response. Check serializers/views to verify the association is used.

7. **Dual rate limiting**: Always pair authenticated throttles with unauthenticated throttles. Unauthenticated requests are the primary attack vector and need lower limits.

## Related Documentation

### SQL Injection Prevention
- `todos/407-complete-p1-sql-interpolation-date-filter.md` — The original finding (flagged by all 6 review agents)
- `todos/050-complete-p2-date-parse-unvalidated-input.md` — Related: unvalidated Date.parse on user input
- `todos/074-complete-p1-html-safe-raw-xss-structural-risk.md` — Injection prevention in views (XSS family)

### Rate Limiting
- `todos/408-complete-p1-rate-limit-bypass-unauthenticated.md` — Unauthenticated bypass finding
- `todos/355-complete-p2-rack-attack-memory-store-not-shared.md` — MemoryStore per-process issue
- `todos/367-complete-p3-rack-attack-account-level-throttle.md` — Distributed brute-force gap
- `docs/solutions/security-issues/mfa-code-review-hardening.md` — MFA rate limiting patterns

### Cache-Control & Health Data
- `todos/409-complete-p1-missing-cache-control-health-data.md` — GDPR Article 9 requirement
- `todos/083-complete-p2-no-cache-control-no-store-on-health-data.md` — Same issue for HTML controllers

### Stimulus Conventions
- `todos/416-complete-p3-inline-onclick-vs-stimulus.md` — Inline onclick finding
- `todos/362-complete-p2-inline-onclick-print-breaks-stimulus.md` — Related print button fix

### Admin UI & Design System
- `todos/222-complete-p2-btn-danger-css-class-undefined-all-views.md` — Undefined CSS classes pattern
- `todos/368-complete-p3-css-table-styling-duplication.md` — Table styling deduplication

### Cross-Cutting
- `docs/solutions/code-quality/pr17-comprehensive-code-review-28-fixes.md` — Previous review cycle (Phases 23-25), covers related patterns
- `docs/solutions/security-issues/authorization-scope-bypass-via-wrong-parent-association.md` — Authorization scoping for APIs
- `.ariadna_planning/phases/28-rest-api/28-CONTEXT.md` — Phase 28 locked decisions

## Verification

```
743 tests, 0 failures, 0 errors
All admin pages styled with design system compliance
Mobile responsive at all breakpoints
```
