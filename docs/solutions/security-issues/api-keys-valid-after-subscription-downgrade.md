---
title: "API keys remain valid after subscription cancellation — missing premium check in API authentication"
category: security-issues
tags:
  - stripe
  - billing
  - api-authentication
  - authorization
  - pay-gem
  - subscription-lifecycle
severity: critical
components:
  - Api::V1::BaseController
  - ApiAuthenticatable
  - PlanLimits
  - ApiKeyPolicy
date_solved: "2026-03-15"
related_phases:
  - 28-rest-api
  - 29-stripe-billing
---

# API Keys Remain Valid After Subscription Cancellation

## Problem Statement

After integrating Stripe billing via the Pay gem (Phase 29), API key generation was gated behind a premium subscription using `ApiKeyPolicy#create?`. However, once a user generated an API key while subscribed, that key continued to authenticate successfully **after the user's subscription was cancelled or expired**.

**Attack scenario:** A user subscribes to Premium, generates an API key, cancels their subscription via Stripe Customer Portal, and continues using the API key for up to 180 days (the key TTL). The user retains full programmatic API access without paying.

This is **privilege escalation via stale authorization** — the system checked *identity* (is this key valid?) but not *entitlement* (does this user still have the right to use the API?).

## Root Cause Analysis

The API authentication flow and the billing/subscription flow were developed as independent concerns with **no runtime coupling**:

1. **`ApiAuthenticatable` concern / `authenticate_api_key!`** in `Api::V1::BaseController` found the user by key digest and set `Current.user`. It verified key validity but never queried subscription status.

2. **`ApiKeyPolicy`** (Pundit) only gated key **creation and destruction** — controlling who can generate or revoke keys. It did not govern key **usage** at request time.

3. **`PLANS[:free][:features][:api_access]`** was set to `false` in the billing configuration, but this value was **dead data** — no controller or middleware ever read it at runtime.

The result: authentication (who are you?) worked correctly, but authorization (are you allowed to do this?) was missing from the API request path.

## Working Solution

Added a subscription status check to `authenticate_api_key!` in `app/controllers/api/v1/base_controller.rb`, inserted **after** identity is established but **before** the request proceeds:

```ruby
def authenticate_api_key!
  token = extract_bearer_token
  if token.blank?
    render_error(status: 401, message: "Missing or invalid Authorization header")
    return
  end

  user = User.authenticate_by_api_key(token)
  if user.nil?
    render_error(status: 401, message: "Invalid API key")
    return
  end

  Current.user = user

  unless user.premium?
    render_error(status: 403, message: "API access requires an active premium subscription")
    return
  end

  Rails.logger.info("[API] user=#{user.id} endpoint=#{request.path} ip=#{request.remote_ip}")
end
```

**Key design decisions:**

- **401 for identity failures, 403 for entitlement failures.** A valid key from a non-premium user returns 403 (Forbidden), not 401. The caller's identity is known, but they lack permission.
- **`Current.user` is set before the premium check.** Logging and error handling can reference the user even when access is denied.
- **`user.premium?`** queries Pay::Subscription records for an active subscription, evaluated on every request so cancellations take effect immediately.

**Test infrastructure updates:**

All API test helpers were updated so test users are made premium via a `make_premium` helper:

```ruby
def make_premium(user)
  user.set_payment_processor :stripe
  user.payment_processor.subscriptions.create!(
    name: "default",
    processor_id: "sub_test_#{user.id}",
    processor_plan: "price_test",
    status: "active",
    type: "Pay::Stripe::Subscription"
  )
  user.payment_processor.reload
end
```

A dedicated test verifies free users get 403:

```ruby
test "returns 403 when user is not premium" do
  free_user = users(:admin_user)
  free_user.update!(role: :member)
  token = free_user.generate_api_key!
  get api_v1_symptom_logs_url, headers: api_headers(token)
  assert_response :forbidden
  error = parsed_response["error"]
  assert_match(/premium/, error["message"])
end
```

## Verification

1. Full API test suite passes: `bin/rails test test/controllers/api/`
2. Free user with valid key gets 403 (not 200)
3. Admin users (always premium) retain API access
4. Response codes are correct: no token = 401, invalid token = 401, valid token + no subscription = 403, valid token + active subscription = 200

## General Principle: Gate at the Point of Use, Not Just Creation

The underlying mistake is assuming that controlling *provisioning* is equivalent to controlling *access*. A resource created while the user was on Plan A continues to exist after they downgrade to Plan B. If the only check was at creation time, the resource becomes an orphaned entitlement — functional but unauthorized.

This applies beyond API keys:

- **Scheduled reports** created by a premium user still fire after downgrade
- **Webhook endpoints** registered during a trial still receive events after the trial ends
- **Team seats** provisioned at a higher tier remain active after a plan change
- **Stored exports or integrations** keep working if only the setup wizard checks the plan

**The rule: if a feature can outlive the subscription tier that enabled it, you must check entitlement at the moment of use, every time.**

## Billing Integration Checklist

- [ ] Every feature gated behind a paid tier has an explicit **runtime** check (not just a creation-time check)
- [ ] `authenticate!` and `authorize!` are separate steps in every controller handling gated functionality
- [ ] Stripe webhook handlers for `subscription.updated` and `subscription.deleted` trigger review/deactivation of tier-dependent resources
- [ ] There is a single source of truth for "what tier is this user on right now?" (no stale caches, no derived booleans stored at creation time)
- [ ] Downgrade paths are explicitly tested: create resource on premium, downgrade to free, attempt to use resource
- [ ] Grace periods, if any, are intentional and documented — not accidental omissions
- [ ] The subscription check is in the base controller or middleware, not individual actions (where it can be forgotten)
- [ ] API responses use 403 with a clear message for subscription-gated denials, distinct from 401 for auth failures

## How This Was Found

Multi-agent code review with 7 parallel review agents. Three agents (security-sentinel, kieran-rails-reviewer, architecture-strategist) independently flagged this gap — strong signal that it is a real architectural issue, not a style preference.

## Related Documentation

- `docs/solutions/code-quality/phase-28-rest-api-code-review-fixes.md` — Phase 28 API auth hardening
- `docs/solutions/code-quality/phase-28-review-cycle-2-hardening.md` — API key TTL (180-day expiry) that determines the exploitation window
- `todos/430-complete-p1-api-keys-work-after-subscription-downgrade.md` — Original review finding

## Key Files

| File | Role |
|------|------|
| `app/controllers/api/v1/base_controller.rb` | Fix location — premium check added here |
| `app/models/concerns/api_authenticatable.rb` | Key validation concern |
| `app/models/concerns/plan_limits.rb` | `premium?` method (memoized) |
| `app/policies/api_key_policy.rb` | Creation/destruction gating (insufficient alone) |
| `test/controllers/api/v1/base_api_test_helper.rb` | `make_premium` helper |
