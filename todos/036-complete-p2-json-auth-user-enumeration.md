---
status: complete
priority: p2
issue_id: "036"
tags: [code-review, security, authentication, api, json]
dependencies: []
---

# JSON Auth Responses Leak Email Verification State — User Enumeration Vector

## Problem Statement

`SessionsController#create` returns different HTTP status codes for two failure cases: `403 Forbidden` when credentials are valid but email is unverified, and `401 Unauthorized` when credentials are wrong. This distinction allows an attacker to enumerate valid registered email addresses: a `403` confirms a matching account with a correct password exists; a `401` means the credentials are wrong.

## Findings

**Flagged by:** security-sentinel (Medium — Finding 2)

**Location:** `app/controllers/sessions_controller.rb`, lines 20-30

```ruby
if user.email_verified_at.present?
  start_new_session_for user
  respond_to do |format|
    format.html { redirect_to after_authentication_url }
    format.json { render json: { session_id: Current.session.id }, status: :created }
  end
else
  respond_to do |format|
    format.html { redirect_to new_session_path, alert: "Please verify your email..." }
    format.json { render json: { error: "Email address not verified" }, status: :forbidden }
  end
end
# vs. wrong credentials:
format.json { render json: { error: "Invalid email address or password" }, status: :unauthorized }
```

**The enumeration attack:**
1. Attacker tries `POST /session` with `email=victim@example.com` + any password. Gets `401`. Account likely doesn't exist or password is wrong.
2. Attacker tries with the right password. Gets `403`. Confirms: account exists, password is correct, email not verified.

**Note:** The HTML path has the same issue (`"Please verify your email..."` vs `"Try another email address or password."`). Both paths leak state.

## Proposed Solutions

### Solution A: Collapse all failures to `401` with a uniform message (Recommended)
```ruby
# When email unverified — return same as wrong credentials:
format.json { render json: { error: "Invalid email address or password" }, status: :unauthorized }
format.html { redirect_to new_session_path, alert: "Try another email address or password." }
```
- **Pros:** Standard security practice (used by GitHub, Google, etc.). Eliminates enumeration.
- **Cons:** Unverified users get a less helpful error. Can be mitigated by triggering a re-send verification email silently.
- **Effort:** Small
- **Risk:** Low

### Solution B: Always respond with `401` but trigger re-send of verification email
```ruby
else
  UserMailer.email_verification(user).deliver_later  # silently re-send
  # Same generic 401 response
end
```
- **Pros:** Still helpful to unverified users without revealing verification state.
- **Cons:** More complex. Could be abused to spam users.
- **Effort:** Medium
- **Risk:** Medium

## Recommended Action

Solution A at minimum. Solution B optionally if UX for unverified users is a concern.

## Technical Details

- **Files:** `app/controllers/sessions_controller.rb`

## Acceptance Criteria

- [ ] `POST /session` with valid email/correct password but unverified account returns `401` (not `403`)
- [ ] `POST /session` with wrong credentials returns `401` with identical body
- [ ] HTML flash message is the same for both unverified and wrong credentials
- [ ] No timing difference observable between the two failure paths

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by security-sentinel as Medium.
