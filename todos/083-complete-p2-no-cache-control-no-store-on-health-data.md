---
status: pending
priority: p2
issue_id: "083"
tags: [code-review, security, privacy, phi, hipaa]
dependencies: []
---

# No `Cache-Control: no-store` on Health Data Responses

## Problem Statement

Rails' default `Cache-Control` for authenticated responses is `max-age=0, private, must-revalidate`. This allows the browser to retain the response in its local cache (bfcache, history cache). On a shared device, another user can read cached health data pages from browser history without a session. For HIPAA-adjacent apps, PHI responses should carry `Cache-Control: no-store` which instructs the browser not to persist the response to any cache.

## Findings

**Flagged by:** security-sentinel (F-07)

**Current:** No cache headers set on `PeakFlowReadingsController` or `SettingsController`. Rails default `private` cache applies but is not `no-store`.

**Risk:** On shared devices (family computer, shared workstation), browser history and bfcache can expose peak flow readings, personal best values, and zone calculations without re-authentication.

## Proposed Solutions

### Option A: `no-store` in ApplicationController for all authenticated requests (Recommended)
**Effort:** Small | **Risk:** Low

```ruby
# app/controllers/application_controller.rb
before_action :set_no_cache_for_authenticated_users, if: :authenticated?

private

def set_no_cache_for_authenticated_users
  response.headers["Cache-Control"] = "no-store"
end
```

Applies to all authenticated responses app-wide. This is the HIPAA-appropriate choice.

### Option B: Per-controller on health data endpoints only
**Effort:** Small | **Risk:** Low

```ruby
# app/controllers/peak_flow_readings_controller.rb
before_action -> { response.headers["Cache-Control"] = "no-store" }
```

Apply to `PeakFlowReadingsController` and `SettingsController`. Less broad but still addresses the PHI pages.

## Recommended Action

Option A — apply `no-store` in `ApplicationController` for all authenticated requests. Consistent with the app's HIPAA-adjacent posture and consistent with how other security headers (HSTS, CSP) are applied globally rather than per-controller.

## Technical Details

**Affected files:**
- `app/controllers/application_controller.rb`

## Acceptance Criteria

- [ ] Authenticated HTML responses include `Cache-Control: no-store`
- [ ] Unauthenticated responses use default Rails caching
- [ ] `bin/rails test` passes with 0 failures

## Work Log

- 2026-03-07: Identified by security-sentinel in Phase 6 code review
