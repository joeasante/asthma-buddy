---
status: pending
priority: p1
issue_id: 440
tags: [code-review, security, billing, revenue]
dependencies: []
---

# Trial Period Manipulation via Repeated Checkout

## Problem Statement

Every checkout session unconditionally includes `trial_period_days: 30`. There is no server-side check for whether the user has previously used a trial. A user can subscribe, cancel before trial ends, wait for subscription to lapse (`user.free?` becomes true), then checkout again for another 30-day free trial — indefinitely.

## Findings

- **Security Sentinel**: Medium severity. Stripe may have partial protections but they are not guaranteed without explicit `trial_settings` configuration.
- **Architecture Strategist**: Not flagged (focused on policy structure).
- **Learnings Researcher**: No prior institutional knowledge on trial manipulation.

## Proposed Solutions

### Solution A: Check subscription history before granting trial (Recommended)
```ruby
def checkout
  # ...
  has_had_subscription = Pay::Subscription.joins(:customer)
    .where(pay_customers: { owner_type: "User", owner_id: Current.user.id })
    .exists?

  trial_days = has_had_subscription ? 0 : PLANS[:premium][:trial_days]

  checkout_session = Current.user.payment_processor.checkout(
    mode: "subscription",
    line_items: price_id,
    subscription_data: trial_days > 0 ? { trial_period_days: trial_days } : {},
    # ...
  )
end
```
- **Pros**: Simple, reliable, server-side enforcement
- **Cons**: Users who cancelled early (never used service) don't get a second chance
- **Effort**: Small
- **Risk**: Low

### Solution B: Use Stripe's trial_settings configuration
Configure `subscription_data.trial_settings.end_behavior.missing_payment_method: "cancel"` and rely on Stripe's per-customer trial tracking.
- **Pros**: Stripe handles deduplication
- **Cons**: Less control, depends on Stripe configuration being correct
- **Effort**: Small
- **Risk**: Medium — configuration-dependent

## Technical Details

- **Affected files**: `app/controllers/settings/billing_controller.rb`
- **Test file**: `test/controllers/settings/billing_controller_test.rb`

## Acceptance Criteria

- [ ] User who previously had a subscription does not get trial_period_days on checkout
- [ ] First-time user still gets 30-day trial
- [ ] Test covers: subscribe → cancel → re-subscribe (no trial)

## Work Log

| Date | Action | Result |
|------|--------|--------|
| 2026-03-15 | Identified by security-sentinel agent | Medium severity finding |

## Resources

- `app/controllers/settings/billing_controller.rb:20-23`
- `app/policies/billing_policy.rb:8-9`
- Stripe docs on trial deduplication
