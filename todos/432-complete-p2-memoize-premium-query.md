---
status: pending
priority: p2
issue_id: 432
tags: [code-review, performance, billing]
dependencies: []
---

# Memoize premium? to Eliminate Redundant DB Queries

## Problem Statement

`premium?` calls `payment_processor&.subscription&.active?` which fires 2 SQL queries (pay_customers + pay_subscriptions). It's called multiple times per request through `free?`, `plan_name`, `plan_features`, `history_cutoff_date`. The billing page alone triggers up to 10 redundant queries returning the same data.

## Findings

- **Source:** Performance Oracle, Rails Reviewer, Architecture Strategist
- **Location:** `app/models/concerns/plan_limits.rb`, line 7
- **Evidence:** No memoization; each call chains through two ActiveRecord associations

## Proposed Solutions

### Option A: Memoize premium? and current_subscription

```ruby
def premium?
  return @_premium if defined?(@_premium)
  @_premium = admin? || payment_processor&.subscription&.active?
end

private

def current_subscription
  return @_current_subscription if defined?(@_current_subscription)
  @_current_subscription = payment_processor&.subscription
end
```

Then rewrite `subscription_status` and `next_billing_date` to use `current_subscription`.

- **Effort:** Small (10 minutes)
- **Risk:** Low (request-scoped, no staleness concern)

## Acceptance Criteria

- [ ] `premium?` called 5 times in a request fires at most 2 SQL queries total
- [ ] All existing tests still pass
- [ ] Billing page renders correctly

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-15 | Created from Phase 29 code review | |
