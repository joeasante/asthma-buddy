---
status: pending
priority: p2
issue_id: "382"
tags: [code-review, security, testing]
dependencies: []
---

## Problem Statement
`role` is correctly excluded from all `params.permit()` calls, but there's no explicit test asserting a user cannot elevate their role via registration or profile update. Given this is a health app with UK GDPR requirements, a regression test would catch any future permit-list mistake.

## Findings
- `role` parameter is not in any `params.permit()` call (correct)
- No test explicitly verifies that submitting `role: "admin"` is ignored
- A future permit-list change could accidentally expose role assignment

## Proposed Solutions
### Option A: Add mass-assignment regression tests
Add tests asserting:
1. `role=admin` in registration params doesn't create an admin
2. `role=admin` in profile update params doesn't change role

**Pros:** Permanent protection, 2 test methods.
**Effort:** Small.
**Risk:** Low.

## Acceptance Criteria
- [ ] Test exists that POSTs `role: "admin"` to registration and asserts `user.role == "member"`
- [ ] Test exists that PATCHes `role: "admin"` to profile and asserts role unchanged
