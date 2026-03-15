---
status: pending
priority: p2
issue_id: 441
tags: [code-review, rails, billing, code-quality]
dependencies: []
---

# Remove Fragile Memoization in PlanLimits Concern

## Problem Statement

`premium?` and `current_subscription` use `defined?(@_variable)` memoization that has no invalidation mechanism. If a subscription is created/modified on the same User object instance, the memoized value is stale. Tests work by coincidence (payment_processor.reload clears enough state), but the concern itself is fragile. The query cost is minimal (one indexed lookup per request), so memoization adds complexity without meaningful performance benefit.

## Findings

- **Kieran Rails Reviewer**: BLOCKING. Recommends removing memoization entirely — cost is a single `payment_processor.subscription` call.
- **Performance Oracle**: Memoization is adequate, no change needed. But confirms the cost of removing it is negligible.
- **Security Sentinel**: Low severity defensive observation — stale values are theoretically possible.

## Proposed Solutions

### Solution A: Remove memoization entirely (Recommended)
```ruby
def premium?
  admin? || (current_subscription&.active? && !paused?) || false
end

private

def current_subscription
  payment_processor&.subscription
end
```
- **Pros**: No stale data risk, simpler code, negligible performance cost
- **Cons**: One extra query per request if premium? called multiple times (but association caching mitigates)
- **Effort**: Small
- **Risk**: None

## Technical Details

- **Affected files**: `app/models/concerns/plan_limits.rb`
- **Test file**: `test/models/plan_limits_test.rb`

## Acceptance Criteria

- [ ] `@_premium` and `@_current_subscription` instance variables removed
- [ ] All existing tests pass
- [ ] No memoization-related instance variables in PlanLimits

## Work Log

| Date | Action | Result |
|------|--------|--------|
| 2026-03-15 | Identified by kieran-rails-reviewer agent | BLOCKING finding |
