---
status: pending
priority: p2
issue_id: "221"
tags: [security, rails, authentication, code-review]
dependencies: []
---

# AccountsController#destroy Uses reset_session Instead of terminate_session — Stale Session Cookie

## Problem Statement

`AccountsController#destroy` calls `reset_session`, which clears the Rack session hash but does NOT:

1. Destroy the `Session` model row in the database
2. Delete the `session_id` signed cookie from the browser

`terminate_session` (defined in the `Authentication` concern) does both. With the current code, the `session_id` cookie persists in the browser for up to 2 weeks after account deletion, pointing to a DB row that may still exist briefly. `SessionsController#destroy` (the normal logout action) correctly calls `terminate_session` — account deletion is inconsistent with this established pattern.

## Findings

**Flagged by:** architecture-strategist, security-sentinel

**Location:**
- `app/controllers/accounts_controller.rb`: `destroy` action calls `reset_session`
- `app/controllers/concerns/authentication.rb`: `terminate_session` defined as: destroy `Current.session` + `cookies.delete(:session_id)`
- `app/models/user.rb`: sessions association has `dependent: :delete_all` — `user.destroy` bulk-deletes session rows, but the browser cookie is never explicitly cleared

**Gap:** Even though `user.destroy` eventually cascades to remove session rows, the browser still holds the `session_id` cookie pointing to a now-deleted row. Any request made with that cookie before the browser expires it would result in a lookup failure or unexpected behaviour.

## Proposed Solutions

### Option A — Use terminate_session before destroy (Recommended)

Replace the current `reset_session` call with the established `terminate_session` pattern, then destroy the user:

```ruby
def destroy
  user = Current.user
  terminate_session          # destroys Session row + deletes session_id cookie
  user.destroy
  redirect_to root_path, notice: "Your account has been permanently deleted."
end
```

**Pros:** Consistent with `SessionsController#destroy`. Cookie is explicitly cleared. Session row is cleanly destroyed before the user record is deleted.
**Cons:** None.
**Effort:** Small
**Risk:** Low

### Option B — Add explicit cookie deletion alongside reset_session

Keep `reset_session` and add the cookie deletion as a minimal fix:

```ruby
reset_session
cookies.delete(:session_id)
```

**Pros:** Minimal diff.
**Cons:** Does not destroy the `Session` DB row explicitly. Inconsistent with the established `terminate_session` pattern.
**Effort:** Very small
**Risk:** Low — but incomplete

## Recommended Action

Option A — replace `reset_session` with `terminate_session` and capture `Current.user` before calling it so the user record is still accessible for destroy. This matches `SessionsController#destroy` and is the correct pattern in this app.

## Technical Details

**Affected files:**
- `app/controllers/accounts_controller.rb`

**Acceptance Criteria:**
- [ ] `session_id` cookie is explicitly deleted after account deletion
- [ ] `Session` DB row is destroyed before the user record is destroyed
- [ ] Pattern matches `SessionsController#destroy` (uses `terminate_session`)
- [ ] Test for deleted user sign-in still passes

## Work Log

- 2026-03-10: Identified by architecture-strategist and security-sentinel in Phase 16 code review.

## Resources

- Rails `reset_session` docs: https://api.rubyonrails.org/classes/ActionController/Metal.html#method-i-reset_session
