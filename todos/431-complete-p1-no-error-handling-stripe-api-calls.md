---
status: pending
priority: p1
issue_id: 431
tags: [code-review, security, billing, error-handling]
dependencies: []
---

# No Error Handling on Stripe API Calls in Billing Controller

## Problem Statement

The `checkout` and `portal` actions in `Settings::BillingController` make direct Stripe API calls with no rescue blocks. If Stripe is down, credentials are misconfigured, or the price ID is invalid, users will see an unhandled 500 error page.

**Why it matters:** Stripe outages happen. Missing/wrong credentials are common in deployments. Users should see a friendly error, not a crash.

## Findings

- **Source:** Rails Reviewer, Architecture Strategist (both flagged independently)
- **Location:** `app/controllers/settings/billing_controller.rb`, lines 11-22 (checkout) and 25-31 (portal)
- **Evidence:** No `rescue` block around `user.payment_processor.checkout(...)` or `user.payment_processor.billing_portal(...)`

## Proposed Solutions

### Option A: Add rescue blocks to both actions

```ruby
def checkout
  authorize :billing, :checkout?
  user = Current.user
  user.set_payment_processor :stripe
  checkout_session = user.payment_processor.checkout(...)
  redirect_to checkout_session.url, allow_other_host: true
rescue Pay::Error, Stripe::StripeError => e
  Rails.logger.error("[Billing] Checkout failed: #{e.message}")
  redirect_to settings_billing_path, alert: "Unable to start checkout. Please try again."
end
```

- **Pros:** Simple, user-friendly, logs the error
- **Cons:** None
- **Effort:** Small
- **Risk:** Low

## Recommended Action

Option A.

## Technical Details

- **Affected files:** `app/controllers/settings/billing_controller.rb`

## Acceptance Criteria

- [ ] Stripe API failure in checkout redirects to billing page with flash alert
- [ ] Stripe API failure in portal redirects to billing page with flash alert
- [ ] Error is logged with `[Billing]` prefix
- [ ] Test verifies rescue behavior (stub Stripe to raise)

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-15 | Created from Phase 29 code review | |

## Resources

- `app/controllers/settings/billing_controller.rb`
