---
status: pending
priority: p3
issue_id: "386"
tags: [code-review, rails, dead-code]
dependencies: []
---

## Problem Statement
`update_role?` is defined in UserPolicy (lines 16-18) but no controller calls it. The controller uses `toggle_admin?` instead. Dead code that could confuse developers reading the policy to understand what actions are authorized.

## Findings
The agent-native reviewer flagged that `update_role?` exists without a corresponding controller action. The controller exclusively uses `toggle_admin?` for role changes, making `update_role?` unreachable dead code.

## Proposed Solutions
### Option A: Remove update_role? from UserPolicy
Delete the `update_role?` method from UserPolicy. If an idempotent `update_role` endpoint is added later (as the agent-native reviewer recommended), re-add it then. Effort: Small.

## Acceptance Criteria
- [ ] UserPolicy has no `update_role?` method
- [ ] All tests pass
