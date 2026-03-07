---
status: pending
priority: p1
issue_id: "019"
tags: [code-review, security, authentication, cookies]
dependencies: []
---

# Session Cookie Missing `secure: true` Flag

## Problem Statement

`app/controllers/concerns/authentication.rb` creates a custom signed cookie without the `secure: true` attribute. Rails' `config.force_ssl = true` (now enabled in production) auto-secures the Rails session store, but this custom `cookies.signed[:session_id]` cookie is independent and must be explicitly marked secure.

## Findings

**Flagged by:** security-sentinel (F-05)

**Location:** `app/controllers/concerns/authentication.rb` line 44

```ruby
# Current — missing secure: true
cookies.signed[:session_id] = {
  value: session.id,
  httponly: true,
  same_site: :lax,
  expires: 2.weeks.from_now
}
```

**Why this matters:**
1. Without `secure: true`, the browser may transmit the cookie over plain HTTP. The window between an HTTP request and the Rails SSL redirect (301) can expose the cookie to tools like sslstrip.
2. `force_ssl = true` automatically secures the built-in `session[]` store, but does **not** cover hand-rolled `cookies.signed[...]` cookies — those require explicit opt-in.
3. In development/test `force_ssl` is off, so the cookie travels over plain HTTP in those environments, which is acceptable but means the attribute matters more in production.

## Proposed Solutions

### Solution A: Environment-aware `secure:` flag (Recommended)
```ruby
cookies.signed[:session_id] = {
  value: session.id,
  httponly: true,
  secure: Rails.env.production?,
  same_site: :lax,
  expires: 2.weeks.from_now
}
```
- **Pros:** Enforces HTTPS cookie transmission in production, keeps development workable without HTTPS setup.
- **Cons:** None.
- **Effort:** Small (1 line)
- **Risk:** None

### Solution B: Always `secure: true`
```ruby
cookies.signed[:session_id] = {
  value: session.id,
  httponly: true,
  secure: true,
  same_site: :lax,
  expires: 2.weeks.from_now
}
```
- **Pros:** Uniform behaviour across all environments.
- **Cons:** Breaks local development without HTTPS setup (causes sign-in to fail over `http://localhost`).
- **Effort:** Small
- **Risk:** Low (dev UX degradation)

## Recommended Action

Solution A. Standard Rails idiom for credentials that must be secure in production but accessible in development.

## Technical Details

- **Affected file:** `app/controllers/concerns/authentication.rb`
- **Line:** ~44 (inside `start_new_session_for`)
- **Related:** `force_ssl = true` was enabled in this same changeset — this cookie should match that security posture

## Acceptance Criteria

- [ ] `cookies.signed[:session_id]` includes `secure: Rails.env.production?`
- [ ] Sign-in still works in development over `http://localhost`
- [ ] `rails test test/controllers/` passes
- [ ] Production cookie includes `Secure` attribute in `Set-Cookie` response header

## Work Log

- 2026-03-06: Identified by security-sentinel during /ce:review of foundation phase changes
