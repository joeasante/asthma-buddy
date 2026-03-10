---
status: pending
priority: p3
issue_id: "237"
tags: [code-review, testing, rails]
dependencies: []
---

# Redundant `sign_out` in "deleted user cannot sign back in" test masks potential regression

## Problem Statement

`accounts_controller_test.rb` test "deleted user cannot sign back in" calls `sign_out` explicitly after `DELETE /account`, but the `destroy` action already calls `reset_session`. The explicit `sign_out` masks a potential regression: if `reset_session` is removed from the controller, the test still passes because `sign_out` handles the session clearing independently. The test should exercise the actual post-destroy state.

## Findings

**Flagged by:** phase-16-code-reviewer

**Location:** `test/controllers/accounts_controller_test.rb`

## Proposed Solutions

### Option A (Recommended) — Remove the explicit `sign_out` call

Let the test rely solely on the post-destroy state from `reset_session` (and eventual `terminate_session` after todo 221 is resolved):

```ruby
# Before
test "deleted user cannot sign back in" do
  sign_in @user
  delete account_path, params: { confirmation: "DELETE" }
  sign_out  # <- remove this line
  post session_path, params: { email_address: @user.email_address, password: "password" }
  assert_response :unauthorized
end

# After
test "deleted user cannot sign back in" do
  sign_in @user
  delete account_path, params: { confirmation: "DELETE" }
  post session_path, params: { email_address: @user.email_address, password: "password" }
  assert_response :unauthorized
end
```

**Effort:** Trivial — remove one line
**Risk:** Low — if the test starts failing after this change, it correctly surfaces a real bug (session not cleared by destroy action)

## Recommended Action

Remove the explicit `sign_out`. The test's purpose is to verify the controller's own session management. If `reset_session` is ever accidentally removed from the controller, the test should catch it.

## Technical Details

**Acceptance Criteria:**
- [ ] Test "deleted user cannot sign back in" does not call `sign_out` explicitly
- [ ] Test still passes
- [ ] Test correctly exercises the controller's own session management

## Work Log

- 2026-03-10: Identified by phase-16-code-reviewer.
