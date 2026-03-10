---
status: pending
priority: p1
issue_id: "219"
tags: [code-review, security, rails, architecture]
dependencies: []
---

# ProfilesController#destroy is an unguarded account deletion bypass

## Problem Statement

`ProfilesController#destroy` (DELETE /profile) permanently deletes the user's account with no confirmation gate. Phase 16 added `AccountsController#destroy` (DELETE /account) with a typed "DELETE" confirmation requirement. Both endpoints now coexist and both destroy the user record. Any actor who can authenticate and send DELETE /profile bypasses the confirmation entirely.

## Findings

- `app/controllers/profiles_controller.rb` lines 80-85: `def destroy` calls `reset_session`, then `user.destroy`, then redirects to root_path with a notice — identical to AccountsController but without the confirmation check
- Route: `resource :profile, only: %i[show update destroy]` maps `DELETE /profile` to `ProfilesController#destroy`
- `app/views/profiles/show.html.erb` — may contain a delete button wired to this endpoint
- Flagged by: architecture-strategist, pattern-recognition-specialist, kieran-rails-reviewer (unanimous across 3 agents)

## Proposed Solutions

### Option A — Recommended

Remove `destroy` from `ProfilesController`. Delete lines 80-85 of `profiles_controller.rb`. Change the route from `resource :profile, only: %i[show update destroy]` to `resource :profile, only: %i[show update]`. Remove any delete button from `profiles/show.html.erb` that targets this endpoint. Delete corresponding test cases.

**Pros:** Eliminates the bypass entirely. A single, well-gated deletion path is easier to audit and reason about. No user-facing regression — the confirmed deletion flow on the accounts page is the correct UX.
**Cons:** None.
**Effort:** Small
**Risk:** None

### Option B — Alternative

Convert `ProfilesController#destroy` to redirect to `settings_path` with an explanation message, keeping the action but making it a no-op redirect.

**Pros:** Slightly softer change — no route removal.
**Cons:** Still leaves a live endpoint. The route responds to DELETE /profile and could be exploited if the redirect logic is bypassed or an error occurs. Confusing to developers reading the codebase. Does not address the root issue.
**Effort:** Small
**Risk:** Low, but leaves technical debt

## Recommended Action

*(leave blank)*

## Technical Details

- Affected files:
  - `app/controllers/profiles_controller.rb`
  - `config/routes.rb`
  - `app/views/profiles/show.html.erb` (may need delete button removed)
  - `test/controllers/profiles_controller_test.rb` (tests for destroy action need removal)
- Components: ProfilesController, AccountsController, routing

## Acceptance Criteria

- [ ] `ProfilesController` has no `destroy` action
- [ ] `config/routes.rb` uses `resource :profile, only: %i[show update]`
- [ ] No route responds to `DELETE /profile`
- [ ] `AccountsController#destroy` (DELETE /account) is the sole account deletion path
- [ ] All tests pass

## Work Log

- 2026-03-10: Identified during Phase 16 code review

## Resources

- PR: Phase 16 execution (commits ba8bbba..e5486b4)
