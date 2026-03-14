---
status: pending
priority: p2
issue_id: "384"
tags: [code-review, rails, architecture]
dependencies: []
---

## Problem Statement
`verify_policy_scoped_for_index` skips `verify_policy_scoped` when `pundit_policy_authorized?` is true. This means a controller calling `authorize SomeModel` on index but loading `SomeModel.all` (unscoped) would pass Pundit's safety net. Currently safe because all controllers scope via `Current.user`, but fragile for future development.

## Findings
- `verify_policy_scoped_for_index` has a conditional bypass when `pundit_policy_authorized?` is true
- A controller could authorize a model class but load unscoped records and pass the check
- All current controllers are safe due to `Current.user` scoping, but this is not enforced

## Proposed Solutions
### Option A: Remove verify_policy_scoped_for_index entirely
Remove `verify_policy_scoped_for_index` and remove `policy_scope` from `Admin::UsersController` (replace with `User.all` since `require_admin` already gates). Simplify to just `verify_authorized`.

**Pros:** Simpler, one verification path.
**Effort:** Small.
**Risk:** Low.

### Option B: Add integration test for index action coverage
Add an integration test that asserts every index action either uses `policy_scope` or is on an explicit allowlist.

**Pros:** Catches regressions.
**Cons:** Test maintenance.
**Effort:** Medium.
**Risk:** Low.

## Acceptance Criteria
- [ ] Either `verify_policy_scoped_for_index` is removed, OR integration test covers all index actions
