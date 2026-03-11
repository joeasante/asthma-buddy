---
title: "terminate_session vs reset_session on Account Deletion"
category: security-issues
tags:
  - sessions
  - authentication
  - account-deletion
  - rails
  - gdpr
  - security
problem_summary: >
  Using reset_session instead of terminate_session on account deletion leaves
  the existing session token valid — the signed cookie persists in the browser
  and the Session DB row is not deleted, allowing a deleted user's session to
  remain technically authenticated until the cookie expires.
affected_versions:
  - Rails 8.1.2
  - Ruby 4.0.1
severity: high
date_added: 2026-03-10
---

# terminate_session vs reset_session on Account Deletion

## Symptom

After deleting their account, the user's signed `session_id` cookie is still present in the browser. If they navigate to a protected page before the cookie expires, the app may not reject them cleanly. The Session DB row for the deleted user still exists in the `sessions` table.

## Root Cause

Rails provides a built-in `reset_session` (part of `ActionController::Base`) that **only clears the Rack session hash in memory**. It does not:
- Delete the Session record from the `sessions` table
- Remove the signed `session_id` cookie from the browser

In a Rails 8 app using the authentication generator (or any custom session-token model), the `Authentication` concern provides `terminate_session`, which does the complete cleanup:

1. `Current.session.destroy` — deletes the Session row from the database
2. `cookies.delete(:session_id)` — removes the signed cookie from the browser

Using `reset_session` instead leaves the cookie and the DB row intact after `user.destroy`, creating a window where the session is technically still valid.

## Investigation Steps

The original destroy action:

```ruby
def destroy
  user = Current.user
  reset_session        # ❌ Only clears Rack session hash
  user.destroy
  redirect_to root_path
end
```

`reset_session` issues no DELETE to the `sessions` table. No cookie is cleared. The browser retains the signed `session_id` cookie. If the user visits a protected route immediately after deletion, the orphaned session row could still be matched by the cookie.

## Working Solution

```ruby
# app/controllers/settings/accounts_controller.rb

def destroy
  if params[:confirmation] == "DELETE"
    user = Current.user
    terminate_session    # ✅ Step 1: destroys Session row AND deletes cookie
    user.destroy         # ✅ Step 2: destroy user (and dependent data)
    redirect_to root_path, notice: "Your account and all associated data have been permanently deleted."
  else
    redirect_to settings_path, alert: "Account not deleted. You must type DELETE exactly to confirm."
  end
end
```

### Why the order matters

`terminate_session` calls `Current.session.destroy`, which requires the Session record to still exist. If `user.destroy` runs first and the User model has `has_many :sessions, dependent: :delete_all` (or `:destroy`), the session row is already gone when `terminate_session` runs — the cookie will not be cleared through the normal path.

**Always call `terminate_session` BEFORE `user.destroy`.**

## Prevention

### Checklist

- [ ] Never use `reset_session` as a substitute for `terminate_session` in apps with a database-backed session model
- [ ] Call `terminate_session` BEFORE `user.destroy`
- [ ] Verify your concern's `terminate_session` clears both the DB row AND the cookie
- [ ] Write a test asserting the old session cookie is rejected after account deletion
- [ ] GDPR compliance: session must be fully terminated at deletion time, not deferred to a background job

### Inspect your terminate_session

```ruby
# Typical Rails 8 authentication generator output
def terminate_session
  Current.session.destroy     # deletes DB row
  cookies.delete(:session_id) # clears browser cookie
end
```

If your version only calls `Current.session.destroy` but does NOT call `cookies.delete`, the client retains the cookie until it expires naturally. Add the cookie deletion explicitly.

### Test Cases

```ruby
test "account deletion terminates the active session" do
  sign_in users(:alice)
  get settings_path
  assert_response :ok

  delete settings_account_path, params: { confirmation: "DELETE" }
  assert_redirected_to root_path

  # Old session cookie must now be rejected
  get settings_path
  assert_redirected_to new_session_path
end

test "deleted user cannot sign in again" do
  alice = users(:alice)
  sign_in alice
  delete settings_account_path, params: { confirmation: "DELETE" }

  post sessions_path, params: { email: alice.email, password: "correct-password" }
  assert_redirected_to new_session_path
end

test "account deletion removes the server-side session record" do
  sign_in users(:alice)
  session_id = Current.session.id

  delete settings_account_path, params: { confirmation: "DELETE" }

  assert_not Session.exists?(session_id), "Session record must be deleted on account deletion"
end
```

## Related

- `docs/solutions/database-issues/active-storage-blob-orphan-on-user-destroy.md` — companion issue: files not purged when user is deleted
