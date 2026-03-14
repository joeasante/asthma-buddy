---
status: complete
priority: p1
issue_id: "393"
tags: [code-review, security, routing, rails-engines]
dependencies: []
---

## Problem Statement
`ApplicationController` uses bare route helpers (`new_session_path` on line 46, `root_path` on line 102) that will break inside mounted engines — the exact same bug pattern just fixed in the Authentication concern and Admin::BaseController for Mission Control Jobs.

## Findings
- **Line 46** (`check_session_freshness`): `redirect_to new_session_path` — resolves against engine routes when request is handled by a mounted engine.
- **Line 102** (`user_not_authorized`): `redirect_back(fallback_location: root_path)` — same engine resolution issue.
- This is the identical root cause documented in `docs/solutions/integration-issues/pundit-rbac-breaks-mounted-engine-mission-control.md`.

## Proposed Solutions
### Option A: Prefix with main_app. (Recommended)
Change both occurrences to `main_app.new_session_path` and `main_app.root_path`. Consistent with the fix already applied in Authentication concern.

**Pros:** Directly matches existing fix pattern, minimal change.
**Cons:** None.
**Effort:** Small.
**Risk:** None.

## Acceptance Criteria
- [ ] `new_session_path` → `main_app.new_session_path` on line 46
- [ ] `root_path` → `main_app.root_path` on line 102
- [ ] Mission Control `/jobs` works when session expires (no routing error)
- [ ] All tests pass
