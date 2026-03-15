---
status: pending
priority: p1
issue_id: 430
tags: [code-review, security, billing, api]
dependencies: []
---

# API Keys Continue Working After Subscription Downgrade

## Problem Statement

When a premium user generates an API key and then cancels their subscription, the API key remains valid and functional. The `ApiAuthenticatable` concern only checks for key existence and TTL — it never verifies the user still has an active premium subscription. This bypasses the paid API access gate entirely.

**Why it matters:** A user can subscribe for one month, generate an API key, cancel, and retain full API access for up to 180 days (the key TTL). This defeats the monetization purpose of gating API access behind premium.

## Findings

- **Source:** Security Sentinel, Rails Reviewer, Architecture Strategist (all flagged independently)
- **Location:** `app/controllers/api/v1/base_controller.rb` — `authenticate_api_key!` method
- **Evidence:** `ApiAuthenticatable#set_user_by_token` finds user by key digest but never checks `user.premium?`
- **Related:** `PLANS[:free][:features][:api_access]` is set to `false` but never checked at runtime

## Proposed Solutions

### Option A: Add premium check to API base controller
Add `user.premium?` check after successful API key authentication in `Api::V1::BaseController`.

```ruby
def authenticate_api_key!
  # ... existing token extraction and user lookup ...
  Current.user = user
  unless user.premium?
    render json: { error: "API access requires an active premium subscription" }, status: :forbidden
    return
  end
end
```

- **Pros:** Simple, clear, enforced at the gateway
- **Cons:** Adds a DB query per API request (mitigated by premium? memoization fix)
- **Effort:** Small
- **Risk:** Low

### Option B: Revoke API keys on subscription cancellation
Subscribe to Pay's webhook events and clear `api_key_digest` when subscription is cancelled.

- **Pros:** Clean — no ongoing runtime check needed
- **Cons:** More complex, relies on webhook reliability, user loses key permanently
- **Effort:** Medium
- **Risk:** Medium (webhook delivery not guaranteed)

### Option C: Both A and B
Belt and suspenders — runtime check + proactive revocation.

- **Pros:** Most secure
- **Cons:** More code
- **Effort:** Medium
- **Risk:** Low

## Recommended Action

Option A (runtime check) is the minimum viable fix. Option C is ideal for production.

## Technical Details

- **Affected files:** `app/controllers/api/v1/base_controller.rb`, `app/models/concerns/api_authenticatable.rb`
- **Components:** API authentication layer
- **Database changes:** None

## Acceptance Criteria

- [ ] Free user with existing API key gets 403 JSON response on API requests
- [ ] Admin user API key always works regardless of subscription
- [ ] Premium user API key works normally
- [ ] Test covers downgrade scenario

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-15 | Created from Phase 29 code review | Flagged by 3 independent review agents |

## Resources

- Phase 29 Stripe Billing commits on main branch
- `app/models/concerns/api_authenticatable.rb` — current auth flow
