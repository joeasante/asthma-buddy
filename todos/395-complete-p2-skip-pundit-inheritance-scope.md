---
status: complete
priority: p2
issue_id: "395"
tags: [code-review, security, pundit, architecture]
dependencies: []
---

## Problem Statement
`skip_pundit` on `Admin::BaseController` disables `verify_authorized` for ALL controllers inheriting from it — not just the Mission Control engine. Any future admin controllers inheriting from `Admin::BaseController` will silently skip Pundit verification. Currently the existing admin controllers (`Admin::DashboardController`, `Admin::UsersController`, `Admin::SiteSettingsController`) call `authorize` explicitly, but there's no safety net if a new admin controller forgets.

## Findings
`class_attribute :_skip_pundit` with `self._skip_pundit = true` on `Admin::BaseController` propagates to all subclasses. This is the expected behavior for Mission Control, but it also means first-party admin controllers lose the deny-by-default protection that `verify_authorized` provides.

Existing todo `380-complete-p2-skip-pundit-inheritance-inversion.md` may be related.

## Proposed Solutions
### Option A: Replace custom skip_pundit with standard skip_after_action (Recommended)
Remove the 12-line custom `skip_pundit` mechanism from ApplicationController (class_attribute, class method, skip_authorization? predicate). Instead, controllers that need to skip use standard `skip_after_action :verify_authorized`. Admin::BaseController uses `skip_after_action :verify_authorized` for engine compatibility, and first-party admin controllers re-enable it with `after_action :verify_authorized`.

**Pros:** Standard Rails/Pundit pattern, -12 lines from ApplicationController, precise per-controller control.
**Effort:** Small.
**Risk:** Low — same behavior, standard mechanism.

### Option B: Add verify_authorized back on first-party admin controllers only
Keep custom mechanism, but each first-party admin controller adds `after_action :verify_authorized` to restore the safety net.

**Pros:** Minimal change.
**Effort:** Small.
**Risk:** Low.

### Option C: Accept current risk with comment
Document that new admin controllers MUST call authorize. Rely on code review.

**Pros:** No code change.
**Effort:** None.
**Risk:** Medium — relies on human diligence.

## Acceptance Criteria
- [ ] First-party admin controllers have verify_authorized restored, OR risk is documented
- [ ] Mission Control engine still works without Pundit errors
- [ ] All tests pass
