---
status: pending
priority: p3
issue_id: 453
tags: [code-review, views, simplification]
dependencies: []
---

# Duplicate "Manage Subscription" Button Blocks in Billing View

## Problem Statement

`app/views/settings/billing/show.html.erb` has two identical "Manage Subscription" button blocks at lines 104-108 (paused) and 110-114 (premium non-admin). These could be collapsed into a single conditional.

## Proposed Solution

Merge into: `if @user.paused? || (@user.premium? && !@user.admin?)`

- **Effort**: Trivial
- **Risk**: None — but depends on #439 (portal policy fix for paused users)
