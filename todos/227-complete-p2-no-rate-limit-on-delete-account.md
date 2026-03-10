---
status: pending
priority: p2
issue_id: "227"
tags: [security, rails, rate-limiting, code-review]
dependencies: []
---

# AccountsController#destroy Has No Rate Limit — Inconsistent with All Other Mutating Controllers

## Problem Statement

Every other sensitive or mutating endpoint in the app has a `rate_limit` declaration: `SessionsController`, `RegistrationsController`, `PasswordsController`, `ProfilesController`, `HealthEventsController`. `AccountsController#destroy` has none.

While the immediate CSRF/blind-attack risk is low (the form requires an authenticated session and a typed confirmation string), rate limiting is a codebase-wide defensive convention that must be applied consistently to all mutating endpoints. An irreversible action that permanently deletes all user health data warrants a tighter limit than standard endpoints.

## Findings

**Flagged by:** security-sentinel, kieran-rails-reviewer

**Location:** `app/controllers/accounts_controller.rb` — no `rate_limit` declaration present

**Reference implementations in codebase:**
- `SessionsController`: `rate_limit to: 10, within: 3.minutes, only: :create`
- `ProfilesController`: `rate_limit to: 10, within: 3.minutes, only: :update`

## Proposed Solutions

### Option A — Tight Limit with Custom Redirect (Recommended)

```ruby
rate_limit to: 3, within: 10.minutes, only: :destroy,
           with: -> { redirect_to settings_path, alert: "Too many deletion attempts. Please try again later." }
```

**Pros:** Tighter than login (appropriate for an irreversible action); redirects to settings with a user-friendly alert; consistent with the `with:` pattern used elsewhere.
**Cons:** None.
**Effort:** Trivial
**Risk:** None

### Option B — Default 429 Response

```ruby
rate_limit to: 5, within: 5.minutes, only: :destroy
```

Uses Rails default 429 response without a custom message.

**Pros:** Even simpler; follows Rails convention.
**Cons:** No user-friendly redirect on HTML clients; produces a raw 429 page rather than redirecting to settings.
**Effort:** Trivial
**Risk:** None

## Recommended Action

Option A. The custom `with:` lambda keeps the user in the app UI (redirects to settings with an alert) rather than serving a bare 429 page. The tighter 3-in-10-minutes window is appropriate for account deletion.

## Technical Details

**Affected files:**
- `app/controllers/accounts_controller.rb`

**Acceptance Criteria:**
- [ ] `AccountsController#destroy` has a `rate_limit` declaration
- [ ] Rate limit is tighter than the 10-in-3-minutes used for login (e.g. 3 in 10 minutes)
- [ ] Rate limit exceeded redirects to settings with an alert message (HTML) or returns 429 (JSON)

## Work Log

- 2026-03-10: Identified by security-sentinel and kieran-rails-reviewer in Phase 16 code review.

## Resources

- Rails `rate_limit` docs: https://api.rubyonrails.org/classes/ActionController/RateLimiting/ClassMethods.html
