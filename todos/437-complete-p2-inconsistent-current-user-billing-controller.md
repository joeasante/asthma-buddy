---
status: pending
priority: p2
issue_id: 437
tags: [code-review, quality, billing]
dependencies: []
---

# Inconsistent Current.user Usage in BillingController

## Problem Statement

Three actions, three different patterns: `show` sets `@user = Current.user`, `checkout` uses local `user = Current.user`, `portal` uses `Current.user` directly. Pick one.

## Findings

- **Source:** Pattern Recognition
- **Location:** `app/controllers/settings/billing_controller.rb`

## Proposed Solutions

Use `Current.user` directly in all actions (matching `portal`). Remove the `@user` instance variable from `show` or keep it only if the view needs it — then use it in checkout too.

- **Effort:** Small (5 minutes)
- **Risk:** None

## Acceptance Criteria

- [ ] Consistent Current.user usage across all billing controller actions
- [ ] All tests pass

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-15 | Created from Phase 29 code review | |
