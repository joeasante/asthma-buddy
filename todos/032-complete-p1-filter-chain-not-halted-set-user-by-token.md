---
status: complete
priority: p1
issue_id: "032"
tags: [code-review, rails, security, authentication, bug]
dependencies: []
---

# `set_user_by_token` Does Not Halt the Filter Chain — `nil` @user Reaches `update`

## Problem Statement

`PasswordsController#set_user_by_token` calls `respond_to` (which renders/redirects) but does not `return` afterward. Rails `before_action` only halts the filter chain if a render or redirect was performed — but the method exits without explicitly returning after the `respond_to unless @user` block. This means `edit` and `update` continue executing with `@user = nil`, causing a `NoMethodError` (`undefined method 'update' for nil`) on any JSON request with an invalid token.

## Findings

**Flagged by:** kieran-rails-reviewer (P1), agent-native-reviewer

**Location:** `app/controllers/passwords_controller.rb`, lines 47-53

```ruby
def set_user_by_token
  @user = User.find_by_token_for(:password_reset, params[:token])
  respond_to do |format|
    format.html { redirect_to new_password_path, alert: "Password reset link is invalid or has expired." }
    format.json { render json: { error: "Password reset link is invalid or has expired." }, status: :not_found }
  end unless @user
  # BUG: method returns here even after rendering, Rails does NOT halt the chain
end
```

`respond_to` itself calls `render` or `redirect_to` but does not `return`. The before_action filter chain checks if a response was committed — which it has been — but the method body has already exited without an explicit return. In practice the action still runs with `@user = nil`.

**Confirmed failure path:** `PATCH /passwords/:token` with invalid token + `Accept: application/json` → `set_user_by_token` renders `{ error: "..." }` → `update` calls `@user.update(...)` → `NoMethodError: undefined method 'update' for nil`.

The HTML path masks this because a double-render would be detected and raise, but in controller flow it's actually the redirect that prevents reaching `@user.update` for HTML clients.

## Proposed Solutions

### Solution A: `return if @user` guard (Recommended)
```ruby
def set_user_by_token
  @user = User.find_by_token_for(:password_reset, params[:token])
  return if @user

  respond_to do |format|
    format.html { redirect_to new_password_path, alert: "Password reset link is invalid or has expired." }
    format.json { render json: { error: "Password reset link is invalid or has expired." }, status: :not_found }
  end
end
```
- **Pros:** Explicit, idiomatic Rails. Success path is clear. Filter chain halts correctly on failure.
- **Cons:** None.
- **Effort:** Small (restructure 6 lines)
- **Risk:** Low

### Solution B: Original pattern with `and return`
```ruby
  redirect_to ... and return unless @user
```
- **Pros:** One-liner.
- **Cons:** Only handles HTML; doesn't work cleanly with `respond_to`.
- **Effort:** Small
- **Risk:** Medium (doesn't cover JSON)

## Recommended Action

Solution A. Also add a controller test: `PATCH /passwords/:token` with invalid token and `as: :json` should return `404` and not raise an error.

## Technical Details

- **File:** `app/controllers/passwords_controller.rb`
- **Lines:** 47-53 (`set_user_by_token`)
- **Before action on:** `edit`, `update`

## Acceptance Criteria

- [ ] `set_user_by_token` returns early when `@user` is present
- [ ] `PATCH /passwords/bad-token` with `Accept: application/json` returns `404` JSON response
- [ ] `PATCH /passwords/bad-token` HTML path still redirects to `new_password_path`
- [ ] No `NoMethodError` possible on nil `@user`

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by kieran-rails-reviewer and agent-native-reviewer.
