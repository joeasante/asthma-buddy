---
status: pending
priority: p1
issue_id: "126"
tags: [code-review, security, ux, authentication]
dependencies: []
---

# Email Verification UX Regression

## Problem Statement

`SessionsController#create` now uses a single guard clause that collapses two distinct failure modes — wrong credentials AND valid-but-unverified account — into the same error message. A user who typed their correct password but has not clicked the email verification link is told "Try another email address or password." This is factually wrong and will cause user confusion, support tickets, and account lockout frustration.

Flagged by: kieran-rails-reviewer, architecture-strategist, pattern-recognition-specialist.

## Findings

**File:** `app/controllers/sessions_controller.rb`, lines 17–26

```ruby
user = User.authenticate_by(params.permit(:email_address, :password))
unless user&.email_verified_at?
  return respond_to do |format|
    format.html { redirect_to new_session_path, alert: "Try another email address or password." }
    format.json { render json: { error: "Invalid email address or password" }, status: :unauthorized }
  end
end
```

When `user` is `nil` (wrong password/email), `user&.email_verified_at?` is `nil`, which is falsy, so the branch fires with "wrong credentials." When `user` is a valid record but `email_verified_at` is `nil`, same branch fires with the same message — the friendly "please verify" UX is lost.

`sessions_controller_test.rb` line 55 validates the regressed message and must be updated once this is fixed.

## Proposed Solutions

**Solution A — Split the guard into two sequential checks (recommended):**
```ruby
user = User.authenticate_by(params.permit(:email_address, :password))

unless user
  return respond_to do |format|
    format.html { redirect_to new_session_path, alert: "Try another email address or password." }
    format.json { render json: { error: "Invalid email address or password" }, status: :unauthorized }
  end
end

unless user.email_verified_at?
  return respond_to do |format|
    format.html { redirect_to new_session_path, alert: "Please verify your email before signing in. Check your inbox for a verification link." }
    format.json { render json: { error: "Email not verified. Check your inbox." }, status: :forbidden }
  end
end
```
- Pros: Restores distinct UX path, semantically correct HTTP status (403 vs 401 for unverified), easy to test
- Cons: None
- Effort: Small

**Solution B — Keep combined guard, update message to cover both cases:**
```ruby
alert: "Check your email address and password, or verify your email address."
```
- Pros: Minimal change
- Cons: Still misleading for verified users who mistyped; obscures the actual problem
- Effort: Small

## Recommended Action

Solution A. Update `sessions_controller_test.rb` to add a test for the unverified-user path that asserts the distinct "Please verify" message.

## Technical Details

- **Affected files:** `app/controllers/sessions_controller.rb`, `test/controllers/sessions_controller_test.rb`
- **HTTP status change:** Unverified user should return 403 (Forbidden) not 401 (Unauthorized) on JSON

## Acceptance Criteria

- [ ] Unverified user with correct password sees "Please verify your email" message (not "wrong credentials")
- [ ] Wrong credentials still see "Try another email address or password."
- [ ] JSON: unverified user returns 403, wrong credentials returns 401
- [ ] `sessions_controller_test.rb` has separate tests for both paths with correct assertions

## Work Log

- 2026-03-08: Identified by code review agents (kieran-rails-reviewer, architecture-strategist, pattern-recognition-specialist)
