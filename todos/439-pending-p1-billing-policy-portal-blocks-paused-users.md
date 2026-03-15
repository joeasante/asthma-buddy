---
status: pending
priority: p1
issue_id: 439
tags: [code-review, security, billing, authorization, bug]
dependencies: []
---

# BillingPolicy#portal? Blocks Paused Users from Resuming Subscription

## Problem Statement

`BillingPolicy#portal?` returns `user.premium? && !user.admin?`, but `premium?` returns `false` for paused users (due to the `!paused?` guard). The billing view shows paused users a "Manage Subscription" button linking to the Stripe Customer Portal, but clicking it triggers a Pundit authorization denial. This is a **dead-end bug** — paused users cannot resume their subscription through the app.

## Findings

- **Architecture Strategist**: Confirmed bug. Paused users are a subset of `free?` users, so `premium?` is false for them. The portal button is rendered (billing view lines 104-108) but the policy blocks access.
- **Security Sentinel**: Noted the policy is correct for preventing unauthorized portal access, but the paused case is a gap.
- **Kieran Rails Reviewer**: Flagged as worth confirming (finding #3).

## Proposed Solutions

### Solution A: Add paused? check to portal policy (Recommended)
```ruby
def portal?
  (user.premium? || user.paused?) && !user.admin?
end
```
- **Pros**: Minimal change, explicit intent, preserves admin exclusion
- **Cons**: None
- **Effort**: Small
- **Risk**: None

### Solution B: Check for subscription existence instead
```ruby
def portal?
  user.payment_processor&.subscription.present? && !user.admin?
end
```
- **Pros**: Covers any subscription state (active, paused, past_due, cancelling)
- **Cons**: Slightly less explicit about intent
- **Effort**: Small
- **Risk**: Low — may allow portal access for cancelled users (which is actually fine — they can resubscribe)

## Technical Details

- **Affected files**: `app/policies/billing_policy.rb`
- **Test file**: `test/controllers/settings/billing_controller_test.rb`

## Acceptance Criteria

- [ ] Paused user can access POST /settings/billing/portal without Pundit denial
- [ ] Test confirms paused user portal access is authorized
- [ ] Admin user still cannot access portal
- [ ] Free user still cannot access portal

## Work Log

| Date | Action | Result |
|------|--------|--------|
| 2026-03-15 | Identified by architecture-strategist agent | Bug confirmed |

## Resources

- `app/policies/billing_policy.rb:11`
- `app/views/settings/billing/show.html.erb:104-108`
- `app/models/concerns/plan_limits.rb:6-9`
