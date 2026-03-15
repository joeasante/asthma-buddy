---
status: pending
priority: p3
issue_id: 451
tags: [code-review, rails, convention]
dependencies: []
---

# PricingController: Swap skip_pundit/allow_unauthenticated_access Order

## Problem Statement

Every other public controller in the codebase places `skip_pundit` before `allow_unauthenticated_access`. `PricingController` reverses this order. Minor convention inconsistency.

## Proposed Solution

Swap lines 4 and 5 in `app/controllers/pricing_controller.rb`.

- **Effort**: Trivial
- **Risk**: None
