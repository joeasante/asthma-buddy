---
status: pending
priority: p3
issue_id: "391"
tags: [code-review, architecture, rails]
dependencies: []
---

## Problem Statement
Admin controllers check admin access twice: `before_action :require_admin` in BaseController AND `authorize` in each action. Both check `admin?`. Defense-in-depth is fine, but when future roles are added (e.g., moderator), both layers must be updated — easy to miss one.

## Findings
The admin namespace BaseController applies a `require_admin` before_action, and then each individual action also calls Pundit's `authorize` which performs its own admin check. Both gates enforce the same constraint through different mechanisms.

## Proposed Solutions
### Option A: Keep both, add a comment documenting the layering
Add a comment in the admin BaseController explaining that `require_admin` is a belt-and-suspenders guard alongside Pundit authorization. Effort: Small.

### Option B: Remove require_admin and rely solely on Pundit
Remove the `require_admin` before_action and let Pundit be the single source of truth for authorization. Pros: single gate to maintain. Cons: loses defense-in-depth. Effort: Small.

## Acceptance Criteria
- [ ] Either documented with an inline comment explaining the dual-guard pattern, or simplified to a single authorization gate
- [ ] All tests pass
