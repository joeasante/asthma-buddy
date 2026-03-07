---
status: pending
priority: p3
issue_id: "061"
tags: [code-review, security, rate-limiting]
dependencies: []
---

# `RegistrationsController` Has No Rate Limiting — Unlimited Account Creation

## Problem Statement

`SessionsController#create` and `PasswordsController#create` are both rate-limited (10 req/3 min per IP). `RegistrationsController#create` has no rate limiting. A bot can create unlimited accounts, exhausting email delivery quota, filling the `users` table, and potentially harvesting valid email addresses through timing differences.

## Findings

**Flagged by:** security-sentinel (INFO-03)

**Location:** `app/controllers/registrations_controller.rb` — no `rate_limit` call

Comparison:
```ruby
# SessionsController — rate limited ✓
rate_limit to: 10, within: 3.minutes, only: :create

# PasswordsController — rate limited ✓
rate_limit to: 10, within: 3.minutes, only: :create

# RegistrationsController — NOT rate limited ✗
class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  # (no rate_limit)
end
```

## Proposed Solution

```ruby
class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    respond_to do |format|
      format.html { redirect_to new_registration_path, alert: "Try again later." }
      format.json { render json: { error: "Too many requests. Try again later." }, status: :too_many_requests }
    end
  }
```

- **Effort:** Small (copy pattern from SessionsController)
- **Risk:** Low — could frustrate batch testing if test isolation isn't careful, but Rails rate_limit uses cache store which is memory-backed in test

## Acceptance Criteria

- [ ] `RegistrationsController#create` is rate-limited
- [ ] Rate limit response has both HTML and JSON paths
- [ ] Test for 429 response when rate limit exceeded

## Work Log

- 2026-03-07: Created from security audit. security-sentinel INFO-03.
