---
status: complete
priority: p3
issue_id: "043"
tags: [code-review, security, authentication, cookies]
dependencies: []
---

# `secure: Rails.env.production?` Cookie Flag Too Narrow — Staging/Review Envs Unprotected

## Problem Statement

The session cookie in `Authentication#start_new_session_for` sets `secure: Rails.env.production?`. If the app is ever deployed to a staging, review, or CI environment using `RAILS_ENV=staging` or a custom environment name over HTTPS, the session cookie will be transmitted without the `Secure` flag even though HTTPS is in use. For a health app, there is no justification for unprotected session cookies on any HTTPS-terminated environment.

## Findings

**Flagged by:** kieran-rails-reviewer (P3), security-sentinel (Low-Medium — Finding 6)

**Location:** `app/controllers/concerns/authentication.rb`, line 45

```ruby
cookies.signed[:session_id] = {
  value: session.id,
  httponly: true,
  secure: Rails.env.production?,
  same_site: :lax,
  expires: 2.weeks.from_now
}
```

**Scenarios where this is incorrect:**
- `RAILS_ENV=staging` deployed with HTTPS → `secure: false`
- Kamal multi-environment deploy with a review app environment → `secure: false`
- The comment `!Rails.env.development?` in the Kieran review is also valid — test env should be excluded too

## Proposed Solutions

### Solution A: Use `!Rails.env.local?` (Recommended)
Rails 7.1+ defines `Rails.env.local?` as `true` for both `development` and `test`. All other environments (production, staging, review, CI with custom env) get `secure: true`.

```ruby
cookies.signed[:session_id] = {
  value: session.id,
  httponly: true,
  secure: !Rails.env.local?,
  same_site: :lax,
  expires: 2.weeks.from_now
}
```
- **Pros:** Future-proof. Any environment that isn't local dev/test gets `Secure`. Idiomatic Rails 7.1+.
- **Effort:** Tiny (1 line)
- **Risk:** None

### Solution B: Rely on `force_ssl: true` in production
`config.force_ssl = true` in `production.rb` instructs `ActionDispatch::SSL` middleware to set the `Secure` flag on all cookies automatically. Redundant with explicit `secure:` in the cookie options, but provides an additional backstop.
- **Pros:** Belt-and-suspenders.
- **Cons:** Still doesn't protect staging if `force_ssl` is only in production.rb.
- **Effort:** None (already in place)

## Recommended Action

Solution A for the cookie option. Both defenses together are better.

## Technical Details

- **File:** `app/controllers/concerns/authentication.rb`, line 45

## Acceptance Criteria

- [ ] `secure:` flag uses `!Rails.env.local?` instead of `Rails.env.production?`
- [ ] In development: cookie is set without `Secure` flag (HTTPS not used locally)
- [ ] In test: cookie is set without `Secure` flag (test environment doesn't use HTTPS)
- [ ] In any other environment: cookie is set with `Secure` flag

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by security-sentinel (Low-Medium), kieran-rails-reviewer (P3).
