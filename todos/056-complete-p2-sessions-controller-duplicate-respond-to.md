---
status: pending
priority: p2
issue_id: "056"
tags: [code-review, quality, simplicity, rails]
dependencies: []
---

# `SessionsController#create` Has Duplicate `respond_to` Blocks — Flatten to Single Guard

## Problem Statement

The unverified-email branch and the authentication-failure branch in `SessionsController#create` produce identical HTML and JSON responses. Two separate `respond_to` blocks say the same thing, adding a level of nesting and 6 extra lines without benefit.

## Findings

**Flagged by:** kieran-rails-reviewer (MEDIUM), code-simplicity-reviewer (Simplification #1)

**Location:** `app/controllers/sessions_controller.rb:16-34`

```ruby
def create
  if user = User.authenticate_by(params.permit(:email_address, :password))
    if user.email_verified_at.present?
      start_new_session_for user
      respond_to do |format|  # success path
        format.html { redirect_to after_authentication_url }
        format.json { render json: { message: "Signed in." }, status: :created }
      end
    else
      respond_to do |format|  # ← DUPLICATE: identical to failure block below
        format.html { redirect_to new_session_path, alert: "Try another email address or password." }
        format.json { render json: { error: "Invalid email address or password" }, status: :unauthorized }
      end
    end
  else
    respond_to do |format|  # ← DUPLICATE
      format.html { redirect_to new_session_path, alert: "Try another email address or password." }
      format.json { render json: { error: "Invalid email address or password" }, status: :unauthorized }
    end
  end
end
```

## Proposed Solutions

### Solution A: Early return guard (Recommended)

```ruby
def create
  user = User.authenticate_by(params.permit(:email_address, :password))

  unless user&.email_verified_at?
    return respond_to do |format|
      format.html { redirect_to new_session_path, alert: "Try another email address or password." }
      format.json { render json: { error: "Invalid email address or password" }, status: :unauthorized }
    end
  end

  start_new_session_for user
  respond_to do |format|
    format.html { redirect_to after_authentication_url }
    format.json { render json: { message: "Signed in." }, status: :created }
  end
end
```

Removes 6 lines, one nesting level, and makes the happy path fall at the bottom. Same security posture (identical error for both failure modes).

- **Effort:** Small
- **Risk:** None — behavior is identical

## Acceptance Criteria

- [ ] `create` action has exactly one failure `respond_to` block
- [ ] All existing `SessionsControllerTest` tests pass
- [ ] Wrong password, unverified email, and successful login paths all tested

## Work Log

- 2026-03-07: Created from code review. kieran-rails-reviewer MEDIUM, code-simplicity-reviewer.
