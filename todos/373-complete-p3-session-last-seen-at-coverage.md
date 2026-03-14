---
status: complete
priority: p3
issue_id: 373
tags: [code-review, security, sessions]
dependencies: []
---

## Problem Statement

`session[:last_seen_at]` is only set in `SessionsController#create`, but the test helper `sign_in_as` bypasses this controller entirely. This means `last_seen_at` is never set in test sessions, and any other session creation path (e.g., future OAuth callbacks) would also miss it.

## Findings

The session timestamp should be set in `Authentication#start_new_session_for` (or equivalent concern method) so that every code path that creates a session automatically sets the timestamp. Currently, only the password-based login flow through `SessionsController#create` sets it, creating a gap.

## Proposed Solutions

- Move the `session[:last_seen_at]` assignment from `SessionsController#create` into `Authentication#start_new_session_for`.
- This ensures every session creation path (controller, test helper, future OAuth, etc.) sets the timestamp.
- Update the test helper if it calls `start_new_session_for` directly.

## Technical Details

**Affected files:** app/controllers/application_controller.rb, app/controllers/concerns/authentication.rb

## Acceptance Criteria

- [ ] `session[:last_seen_at]` is set in `Authentication#start_new_session_for`
- [ ] All session creation paths (login, test helper, any future paths) set the timestamp
- [ ] Existing session-related tests pass
- [ ] No regression in session timeout or activity tracking behavior
