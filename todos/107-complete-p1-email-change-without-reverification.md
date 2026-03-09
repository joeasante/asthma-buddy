---
status: pending
priority: p1
issue_id: "107"
tags: [code-review, security, authentication, account-takeover, rails]
dependencies: []
---

# Email address changeable without re-verification — account takeover vector

## Problem Statement

`ProfilesController#update` allows changing `email_address` via a PATCH request with no email ownership verification. The app uses email verification tokens on signup (`EmailVerificationsController`) to confirm the user owns their address. Bypassing this on email change means: (1) a user can change their address to one they don't own, locking another account out of password reset; (2) an attacker who gains brief session access can silently redirect all future communications.

## Findings

- `app/controllers/profiles_controller.rb` — `profile_params` permits `:email_address`; `Current.user.update(update_attrs)` applies it directly
- `app/controllers/email_verifications_controller.rb` — email verification flow exists but is only triggered at registration
- `app/models/user.rb` — no `before_save :require_verification_on_email_change` or similar guard
- Security Sentinel and Architecture Strategist both flagged independently

## Proposed Solutions

### Option A: Remove email from profile_params (Recommended near-term)
Exclude `:email_address` from `profile_params` for now. Display current email as read-only. Add a dedicated "Change email" flow later.
```ruby
def profile_params
  params.require(:user).permit(:full_name, :date_of_birth, :password, :password_confirmation, :avatar)
end
```
**Pros:** Eliminates the vulnerability immediately. Zero regression risk.
**Cons:** Removes an advertised feature until a proper flow is built.
**Effort:** Small | **Risk:** Low

### Option B: Require current password before email change
In `ProfilesController#update`, if `email_address` is changing, require `current_password` authentication (same pattern already used for password change).
**Pros:** Adds friction without a full re-verification flow.
**Cons:** Still doesn't confirm ownership of the new address.
**Effort:** Small | **Risk:** Medium

### Option C: Full email change flow with verification
Add a pending_email column. On email change request, send a verification link to the new address. Only commit the change after the link is clicked.
**Pros:** Proper, industry-standard approach.
**Cons:** Significant scope — new column, mailer, token controller, UI.
**Effort:** Large | **Risk:** Low (if done correctly)

## Recommended Action

Option A immediately to close the vulnerability. Option C as a future milestone.

## Technical Details

- **Affected files:** `app/controllers/profiles_controller.rb`
- **Security impact:** Account takeover, email hijacking

## Acceptance Criteria

- [ ] Email address cannot be changed to an unverified address
- [ ] Either: email is excluded from profile update params, OR a re-verification step is enforced
- [ ] Test covering attempt to change email via PATCH /profile is present in `profiles_controller_test.rb`

## Work Log

- 2026-03-08: Identified by security-sentinel and architecture-strategist during PR review
