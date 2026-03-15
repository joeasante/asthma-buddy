---
status: pending
priority: p2
issue_id: 443
tags: [code-review, security, billing, rate-limiting]
dependencies: []
---

# Add Rate Limiting to Billing Checkout and Portal Endpoints

## Problem Statement

No Rack::Attack throttle rules exist for `POST /settings/billing/checkout` or `POST /settings/billing/portal`. An authenticated attacker could rapidly create Stripe Checkout Sessions, generating excessive Stripe API costs or triggering account-level rate limits.

## Proposed Solution

Add to `config/initializers/rack_attack.rb`:
```ruby
throttle("billing/checkout", limit: 5, period: 1.minute) do |req|
  req.ip if req.path == "/settings/billing/checkout" && req.post?
end

throttle("billing/portal", limit: 5, period: 1.minute) do |req|
  req.ip if req.path == "/settings/billing/portal" && req.post?
end
```

- **Effort**: Small
- **Risk**: None

## Acceptance Criteria

- [ ] Checkout endpoint throttled at 5 requests/minute
- [ ] Portal endpoint throttled at 5 requests/minute
- [ ] Test confirms 429 response after exceeding limit
