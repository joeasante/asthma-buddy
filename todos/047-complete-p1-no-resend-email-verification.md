---
status: pending
priority: p1
issue_id: "047"
tags: [code-review, authentication, email, ux]
dependencies: []
---

# No Resend Email Verification Flow — Users Permanently Locked Out

## Problem Statement

There is no endpoint, controller action, or UI element for resending the email verification email. A user whose verification email expired (24-hour window), landed in spam, or was never received has no recovery path: attempting to re-register fails with a uniqueness error on the email address, and the support flow is undefined. This is a user-blocking dead end that will manifest in production within the first week.

## Findings

**Flagged by:** kieran-rails-reviewer (CRITICAL), agent-native-reviewer (WARNING), architecture-strategist (HIGH)

**Root cause:** The verification email is sent exactly once at registration via `UserMailer.email_verification(@user).deliver_later` in `RegistrationsController#create`. The `EmailVerificationsController` has only a `show` action (token verification). There is no `new` or `create` action, no route, and no link in the UI to resend.

**Related files:**
- `app/controllers/email_verifications_controller.rb` — only has `show`
- `app/controllers/registrations_controller.rb:13` — only send point
- `app/mailers/user_mailer.rb` — `email_verification` method exists
- `config/routes.rb:3` — `get "email_verification/:token"` only

**Impact for agents:** An agent that registers, receives 201, then tries to sign in gets 401 with "Invalid email address or password" — indistinguishable from wrong credentials. No recovery signal is available.

## Proposed Solutions

### Solution A: Add resend endpoint on EmailVerificationsController (Recommended)

Add `new` + `create` actions and routes:

```ruby
# config/routes.rb
resource :email_verification, only: %i[ show ] do
  collection do
    get :new, path: "email_verification/new"
    post :create, path: "email_verification"
  end
end
```

Or simpler:
```ruby
get "email_verification/new", to: "email_verifications#new", as: :new_email_verification
post "email_verification", to: "email_verifications#create", as: :resend_email_verification
get "email_verification/:token", to: "email_verifications#show", as: :email_verification
```

Controller:
```ruby
# EmailVerificationsController
allow_unauthenticated_access only: %i[ show new create ]

def new; end  # renders form asking for email address

def create
  if user = User.find_by(email_address: params[:email_address])
    unless user.email_verified_at?
      UserMailer.email_verification(user).deliver_later
    end
  end
  # Always same response — enumeration prevention
  respond_to do |format|
    format.html { redirect_to new_session_path, notice: "Verification email sent (if your account needs it)." }
    format.json { render json: { message: "Verification email sent (if your account needs it)." }, status: :ok }
  end
end
```

- **Pros:** Follows PasswordsController pattern exactly. Enumeration-safe (same message regardless of user existence/verified state). Minimal new code.
- **Effort:** Small
- **Risk:** Low

### Solution B: Add resend link to login flash message

When login fails for an unverified account (detected internally but not exposed), show a generic "didn't receive verification email?" link on the login page.
- **Pros:** No new endpoint required
- **Cons:** Requires exposing unverified status to some degree, or making the link always visible
- **Effort:** Small
- **Risk:** Medium (UX decisions around revealing account status)

## Technical Details

- **New files needed:** `app/views/email_verifications/new.html.erb`
- **Modified files:** `app/controllers/email_verifications_controller.rb`, `config/routes.rb`
- **Test file needed:** `test/controllers/email_verifications_controller_test.rb` (add new/create tests)
- **Rate limiting:** The `create` action should be rate-limited (same as `PasswordsController#create` — 10 req/3 min) to prevent verification email spam

## Acceptance Criteria

- [ ] A user whose verification email expired or was lost can request a new one
- [ ] The resend action returns identical responses regardless of whether the email/account exists (enumeration prevention)
- [ ] Rate limiting is applied to the resend action
- [ ] The login or sign-up page includes a link to the resend flow
- [ ] JSON API support: `POST /email_verification` returns 200 with message
- [ ] Test coverage for: successful resend, already-verified account resend (still returns 200), non-existent email (still returns 200)

## Work Log

- 2026-03-07: Created from multi-agent code review. Flagged by kieran-rails-reviewer (CRITICAL), agent-native-reviewer (P1), architecture-strategist (P1).
