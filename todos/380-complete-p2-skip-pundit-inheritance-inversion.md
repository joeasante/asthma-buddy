---
status: pending
priority: p2
issue_id: "380"
tags: [code-review, security, rails]
dependencies: []
---

## Problem Statement
`Settings::BaseController` calls `skip_pundit`, then 3 child controllers manually set `self._skip_pundit = false` to re-enable. Any new controller inheriting from Settings::BaseController will silently skip ALL authorization — a latent security risk for health data. Multiple review agents flagged this independently (Rails, Security, Architecture, Pattern).

## Findings
- `Settings::BaseController` disables Pundit globally for its hierarchy
- 3 child controllers opt back in by setting `self._skip_pundit = false`
- Any new Settings child controller would inherit the skip, silently bypassing authorization
- Flagged independently by Rails, Security, Architecture, and Pattern review agents

## Proposed Solutions
### Option A: Move skip_pundit to only the controller that needs it
Remove `skip_pundit` from `Settings::BaseController`. Only `SettingsController` (the landing page) needs it — add `skip_pundit` there instead. Remove the 3 `self._skip_pundit = false` lines from child controllers.

**Pros:** Safe default, no opt-back-in needed.
**Effort:** Small.
**Risk:** Low.

## Acceptance Criteria
- [ ] `Settings::BaseController` does NOT call `skip_pundit`
- [ ] New Settings child controllers inherit Pundit enforcement by default
- [ ] Existing tests pass
