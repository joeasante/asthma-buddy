---
status: pending
priority: p3
issue_id: 428
tags: [code-review, testing, admin]
dependencies: []
---

# No system tests for restyled admin pages

## Problem Statement

The admin dashboard and users pages were restyled from scratch but no new or modified system tests exist for these views. A smoke test verifying they render without errors for an admin user would catch regressions.

## Findings

- **Source**: kieran-rails-reviewer (Finding #16)
- **Location**: `app/views/admin/dashboard/index.html.erb`, `app/views/admin/users/index.html.erb`

## Proposed Solutions

### Option A: Add admin smoke system tests
- **Approach**: System tests that visit admin dashboard and users pages as an admin user, assert key elements render
- **Effort**: Small
- **Risk**: Low

## Acceptance Criteria

- [ ] System test visits admin dashboard as admin — asserts 200 and key elements
- [ ] System test visits admin users as admin — asserts 200 and key elements

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from code review | |

## Resources

- PR #24: https://github.com/joeasante/asthma-buddy/pull/24
