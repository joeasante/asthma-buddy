---
status: pending
priority: p2
issue_id: 442
tags: [code-review, rails, billing, authorization]
dependencies: []
---

# Make Trialing-as-Premium Contract Explicit in premium?

## Problem Statement

`premium?` relies on Pay's `active?` returning true for trialing subscriptions — an implicit contract. If Pay ever changes this behavior, every trial user silently loses premium access in a health app. The codebase explicitly handles trial state everywhere else (`on_trial?`, `subscription_status`), but the critical authorization gate is implicit.

## Findings

- **Kieran Rails Reviewer**: BLOCKING. Recommends making the intent explicit with `sub.on_trial?` check.

## Proposed Solution

```ruby
def premium?
  return true if admin?
  sub = current_subscription
  sub.present? && (sub.active? || sub.on_trial?) && sub.status != "paused"
end
```

- **Effort**: Small
- **Risk**: None — additive check, does not change behavior

## Technical Details

- **Affected files**: `app/models/concerns/plan_limits.rb`

## Acceptance Criteria

- [ ] `premium?` explicitly checks `on_trial?` alongside `active?`
- [ ] All existing tests pass
- [ ] Comment documents the intent: "Trial users ARE premium"
