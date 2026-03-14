---
title: "Phase 28 REST API — Review Cycle 2 Hardening"
problem_type: code_quality
modules: [api_v1, authentication, rate_limiting, api_keys, clipboard, health_events, admin]
tags: [code-review, security, rack-attack, bearer-token, api-key-expiry, audit-logging, cache-control, turbo-confirm, clipboard, date-parsing, arel]
severity: mixed
date_solved: 2026-03-14
related:
  - docs/solutions/code-quality/phase-28-rest-api-code-review-fixes.md
  - docs/solutions/security-issues/mfa-code-review-hardening.md
  - docs/solutions/code-quality/pr17-comprehensive-code-review-28-fixes.md
---

# Phase 28 REST API — Review Cycle 2 Hardening

## Problem

After the initial Phase 28 REST API implementation was merged (PR #24), a comprehensive 8-agent code review (`/ce:review`) identified 13 findings across 3 severity levels: 3 P1 (critical), 7 P2 (important), 3 P3 (nice-to-have). These covered security gaps, missing expiration logic, duplicated code, and absent test coverage.

## Symptoms

- **P1 #417**: Rack::Attack responder only matched one throttle rule name (`api/v1/requests`) — the unauthenticated throttle (`api/v1/unauthenticated`) returned HTML instead of JSON on 429.
- **P1 #418**: Generating a new API key when one already existed had no confirmation dialog — silent replacement with no undo.
- **P1 #419**: API key display page lacked `Cache-Control: no-store` — browser could cache the plaintext key.
- **P2 #420**: API keys never expired — no TTL enforcement.
- **P2 #421**: No audit logging for API access, key generation, or revocation.
- **P2 #422**: `Date.parse` accepted ambiguous formats like `"March 14"` — should enforce ISO 8601.
- **P2 #423**: Bearer token regex duplicated 3 times across rack_attack, base_controller, and api_authenticatable.
- **P2 #424**: No test coverage for unauthenticated rate limiting.
- **P2 #425**: Clipboard controller had no `.catch()` handler for write failures.
- **P3 #426**: Health events API response missing `ended_at` and `ongoing` fields.
- **P3 #427**: Medications controller silently ignored date params (documented as won't-fix).
- **P3 #428**: No admin system tests existed.
- **P3 #429**: Rate limit tests were slow due to 61-iteration loops (accepted as necessary).

## Root Cause

The initial implementation focused on core functionality (authentication, CRUD, Pundit scoping, serialization) but left gaps in operational hardening: no key expiry, no audit trail, inconsistent error responses, missing confirmation UX, and duplicated constants.

## Solution

### 1. Rack::Attack responder fix (P1 #417)

Changed exact string match to prefix match so both API throttle rules return structured JSON:

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttled_responder = lambda do |request|
  matched = request.env["rack.attack.match_discriminator"] || request.env["rack.attack.matched"]

  if matched.start_with?("api/v1/")
    # Returns JSON with Retry-After for ALL api/v1/* throttles
  end
end
```

Also extracted `EXTRACT_API_TOKEN` lambda to DRY up token extraction across both throttle rules.

### 2. Turbo confirm on key replacement (P1 #418)

```erb
<%= button_to "Generate API Key", settings_api_key_path, method: :post,
      data: @has_key ? { turbo_confirm: "This will replace your existing API key..." } : {} %>
```

### 3. Cache-Control on key display (P1 #419)

```ruby
# app/controllers/settings/api_keys_controller.rb
def create
  # ... generate key ...
  response.headers["Cache-Control"] = "no-store"
end
```

### 4. API key expiration — 180-day TTL (P2 #420)

```ruby
# app/models/concerns/api_authenticatable.rb
BEARER_PATTERN = /\ABearer\s+([a-f0-9]{64})\z/
API_KEY_TTL = 180.days

def self.authenticate_by_api_key(token)
  # ... find user by digest ...
  return nil if user&.api_key_expired?
  user
end

def api_key_expired?
  return false unless api_key_created_at.present?
  api_key_created_at < API_KEY_TTL.ago
end
```

### 5. Audit logging (P2 #421)

```ruby
# API access
Rails.logger.info("[API] user=#{user.id} endpoint=#{request.path} ip=#{request.remote_ip}")

# Key lifecycle
Rails.logger.info("[API Key] action=generate user=#{Current.user.id} ip=#{request.remote_ip}")
Rails.logger.info("[API Key] action=revoke user=#{Current.user.id} ip=#{request.remote_ip}")
```

### 6. Strict ISO 8601 date parsing (P2 #422)

```ruby
def parse_iso_date(value)
  Date.strptime(value, "%Y-%m-%d")
rescue Date::Error, ArgumentError
  raise InvalidDateParam, "Invalid date format. Use YYYY-MM-DD."
end
```

### 7. Bearer pattern constant (P2 #423)

`ApiAuthenticatable::BEARER_PATTERN` replaces 3 inline regex occurrences.

### 8. Clipboard error handling (P2 #425)

```javascript
navigator.clipboard.writeText(text).then(() => {
  this.element.textContent = "Copied!"
  setTimeout(() => { this.element.textContent = original }, 2000)
}).catch(() => {
  this.element.textContent = "Failed to copy"
  setTimeout(() => { this.element.textContent = original }, 2000)
})
```

### 9. Health events API fields (P3 #426)

Added `ended_at` and computed `ongoing` boolean to the serialized response.

### 10. Admin system tests (P3 #428)

3 smoke tests: dashboard renders for admin, users page renders, non-admin redirected.

## Tests Added

- 5 API key expiration tests (`user_api_key_test.rb`)
- 2 unauthenticated rate limiting tests (`rate_limiting_test.rb`)
- Cache-Control assertion (`api_keys_controller_test.rb`)
- Updated health events expected fields (`health_events_controller_test.rb`)
- 3 admin system tests (`admin_test.rb`)

All 750 tests pass.

## Prevention

1. **Use `/ce:review` after every phase** — catches operational gaps early.
2. **Always add `Cache-Control: no-store`** when rendering secrets (API keys, tokens, passwords).
3. **Extract constants for shared patterns** — regex, TTL values, format strings.
4. **Add `turbo_confirm` on destructive actions** — especially irreversible ones like key replacement.
5. **Enforce strict date parsing** with `Date.strptime` — never use `Date.parse` for user input.
6. **Add `.catch()` to all clipboard operations** — not all browsers/contexts support it.
7. **Audit log all security-sensitive actions** — key generation, revocation, API access.

### CI Checks to Consider

| Check | What it catches |
|---|---|
| `grep -rn 'Date\.parse' app/` returns 0 | Ambiguous date parsing (#422) |
| `grep -rn 'Bearer' app/ config/ \| grep -v BEARER_PATTERN` | Duplicated regex (#423) |
| `grep -rn 'method: :delete' app/views/ \| grep -v turbo_confirm` | Missing confirmation (#418) |
| `grep -rn '\.then(' app/javascript/ \| grep -v '\.catch('` | Unhandled promise rejections (#425) |
| Every Rack::Attack throttle rule has 2+ tests | Missing rate limit coverage (#424) |

## Cross-References

### Prior Findings in Same Areas

- **Rate limiting:** #408 (added unauthenticated throttle), #413 (test route fix), #372 (response format), #355 (MemoryStore), #079 (JSON handler)
- **API key security:** #414 (key from flash cookie), #415 (tighten bearer regex), #409 (cache headers on API), #083 (cache-control on health data)
- **Date parsing:** #407 (SQL injection in date filter), #411 (nil return convention), #050 (unvalidated Date.parse), #094 (rescue nil widens query)
- **DRY violations:** #153 (Ruby/JS constant duplication), #194 (GINA thresholds), #339 (cache key literals)
- **API response gaps:** #130 (triggers missing from symptom logs), #139 (profile missing avatar), #296 (dose puffs missing)
- **Admin tests:** #374 (admin fixture missing), #293 (dashboard feature tests missing)

### Related Documentation

- [Phase 28 Review Cycle 1](phase-28-rest-api-code-review-fixes.md) — 10 fixes from initial review
- [MFA Code Review Hardening](../security-issues/mfa-code-review-hardening.md) — re-authentication patterns
- [PR #17 Comprehensive Review](pr17-comprehensive-code-review-28-fixes.md) — earlier review methodology
