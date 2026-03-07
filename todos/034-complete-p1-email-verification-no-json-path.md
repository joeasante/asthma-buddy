---
status: complete
priority: p1
issue_id: "034"
tags: [code-review, authentication, agent-native, api, json]
dependencies: []
---

# `EmailVerificationsController#show` Has No JSON Path — Agent-Registered Accounts Can Never Sign In

## Problem Statement

`EmailVerificationsController#show` handles only HTML redirects for all three verification outcomes (invalid token, already verified, success). Because `POST /session` rejects users with `email_verified_at: nil`, any agent that programmatically registers a new account is permanently blocked from signing in — email verification requires human action on an HTML endpoint. This is an end-to-end lifecycle break.

## Findings

**Flagged by:** agent-native-reviewer (Critical Issue 2)

**Location:** `app/controllers/email_verifications_controller.rb`

```ruby
def show
  user = User.find_by_token_for(:email_verification, params[:token])

  if user.nil?
    redirect_to new_session_path, alert: "Invalid or expired verification link."
  elsif user.email_verified_at.present?
    redirect_to new_session_path, notice: "Email already verified."
  else
    user.update!(email_verified_at: Time.current)
    redirect_to new_session_path, notice: "Email verified! You can now sign in."
  end
end
```

**Impact:** An agent that calls `POST /registration` receives a `201` JSON response and an email containing a verification URL. The agent can `GET /email_verification/:token` — but receives a `302` redirect to the login form regardless of format. The account remains unverified. `POST /session` returns `403 { error: "Email address not verified" }`. The agent is permanently stuck.

This also affects CI-based fixture provisioning, integration test bots, and any programmatic onboarding flow.

## Proposed Solutions

### Solution A: Add `respond_to` to all three branches (Recommended)
```ruby
def show
  user = User.find_by_token_for(:email_verification, params[:token])

  if user.nil?
    respond_to do |format|
      format.html { redirect_to new_session_path, alert: "Invalid or expired verification link." }
      format.json { render json: { error: "Invalid or expired verification link." }, status: :not_found }
    end
  elsif user.email_verified_at.present?
    respond_to do |format|
      format.html { redirect_to new_session_path, notice: "Email already verified." }
      format.json { render json: { message: "Email already verified." }, status: :ok }
    end
  else
    user.update!(email_verified_at: Time.current)
    respond_to do |format|
      format.html { redirect_to new_session_path, notice: "Email verified! You can now sign in." }
      format.json { render json: { message: "Email verified. You can now sign in." }, status: :ok }
    end
  end
end
```
- **Pros:** Completes the JSON auth lifecycle. Standard pattern matching other controllers.
- **Cons:** None.
- **Effort:** Small
- **Risk:** Low

### Solution B: API token in verification email
Include a one-time machine-readable token that can be exchanged for a session without requiring the full web flow. More complex, only needed for headless environments.
- **Effort:** Large
- **Risk:** Medium

## Recommended Action

Solution A. Minimal change that unblocks the agent auth lifecycle without architectural changes.

## Technical Details

- **File:** `app/controllers/email_verifications_controller.rb`
- **Route:** `GET /email_verification/:token`

## Acceptance Criteria

- [ ] `GET /email_verification/:token` with valid token and `Accept: application/json` returns `200 { "message": "Email verified. You can now sign in." }`
- [ ] `GET /email_verification/:token` with invalid token and `Accept: application/json` returns `404 { "error": "Invalid or expired verification link." }`
- [ ] `GET /email_verification/:token` with already-verified and `Accept: application/json` returns `200 { "message": "Email already verified." }`
- [ ] HTML paths unchanged

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by agent-native-reviewer as Critical Issue 2.
