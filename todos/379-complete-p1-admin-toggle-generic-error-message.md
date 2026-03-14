---
status: pending
priority: p1
issue_id: "379"
tags: [code-review, ux, rails]
dependencies: []
---

## Problem Statement
The old toggle_admin gave specific messages: "Cannot remove the last admin" and "You cannot change your own admin status." Now both cases trigger Pundit::NotAuthorizedError with the generic "You are not authorized to perform this action." Admins cannot distinguish between self-demotion and last-admin protection.

## Findings
Moving the last-admin and self-demotion guards into `UserPolicy#toggle_admin?` means both failure cases raise the same `Pundit::NotAuthorizedError`. The global rescue handler in ApplicationController maps all such errors to a single generic message, destroying the specific feedback that previously helped admins understand why their action was blocked.

## Proposed Solutions
### Option A: Move last-admin and self-demotion checks back to controller with specific flash messages
- Keep Pundit for the general admin-only authorization check, but perform last-admin and self-demotion checks in the controller before the update, with specific flash messages
- Pros: specific UX, simple
- Cons: some duplication with policy
- Effort: Small
- Risk: Low

### Option B: Catch NotAuthorizedError in toggle_admin and map policy reasons to messages
- Pros: keeps logic in policy
- Cons: Pundit doesn't natively support reason codes, more complex
- Effort: Medium
- Risk: Medium

## Acceptance Criteria
- [ ] Self-demotion attempt shows "You cannot change your own admin status"
- [ ] Last-admin demotion attempt shows "Cannot remove the last admin"
- [ ] Unauthorized member access still gets generic 403
