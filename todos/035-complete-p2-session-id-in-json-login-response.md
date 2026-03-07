---
status: complete
priority: p2
issue_id: "035"
tags: [code-review, security, api, authentication, json]
dependencies: []
---

# `session_id` Integer PK Returned in JSON Login Response — Misleading and Exposes Internal ID

## Problem Statement

`SessionsController#create` returns `{ session_id: Current.session.id }` in the JSON success path. This is a raw database integer primary key. It implies to API consumers that this value is a bearer credential, but the `Authentication` concern exclusively resolves sessions via a Rails-signed cookie — the integer alone is not usable. The field is both misleading and leaks an internal sequential ID.

## Findings

**Flagged by:** kieran-rails-reviewer (P3), security-sentinel (High), architecture-strategist (High), agent-native-reviewer (Warning), code-simplicity-reviewer

**Location:** `app/controllers/sessions_controller.rb`, line 21

```ruby
format.json { render json: { session_id: Current.session.id }, status: :created }
```

**Problems:**
1. **Not a usable credential.** `Authentication#find_session_by_cookie` reads only `cookies.signed[:session_id]`. A signed cookie contains an HMAC digest — an agent receiving integer `42` cannot reconstruct `session_id=42--<hmac>`. The actual credential is in the `Set-Cookie` response header, not the body.
2. **Sequential enumerable ID.** Database PKs are sequential. Exposing them in API responses allows session table enumeration.
3. **HIPAA-adjacent.** For a health app, session identifiers in response bodies may appear in access logs, proxies, and monitoring tools.
4. **Stale jbuilder comment in ApplicationController** implies jbuilder views exist — they don't. All JSON is rendered inline.

## Proposed Solutions

### Solution A: Return `head :created` (Simplest)
```ruby
format.json { head :created }
```
- **Pros:** The signed cookie is already set by `start_new_session_for`. A `201 No Content` correctly signals success without exposing internals.
- **Cons:** Clients cannot distinguish "signed in" from a generic 201. Minimal but correct.
- **Effort:** Tiny (1 line)
- **Risk:** None

### Solution B: Return a confirmation message (Recommended)
```ruby
format.json { render json: { message: "Signed in." }, status: :created }
```
- **Pros:** Human-readable, consistent with other success responses (`{ message: "..." }`). Doesn't expose internal IDs.
- **Cons:** None.
- **Effort:** Tiny
- **Risk:** None

### Solution C: Return a proper opaque session token (Future)
Add a `token` column (random, cryptographically secure) to `sessions`, return it here, add `Authorization: Bearer` lookup to `Authentication`. Enables stateless mobile clients.
- **Effort:** Large (migration + auth changes)
- **Risk:** Medium

## Recommended Action

Solution B in the short term. Solution C if/when a mobile companion app is planned.

Also remove the stale comment from `ApplicationController` that refers to jbuilder views.

## Technical Details

- **File:** `app/controllers/sessions_controller.rb`, line 21

## Acceptance Criteria

- [ ] `POST /session` with `Accept: application/json` and valid credentials returns `201` with `{ "message": "Signed in." }` (no `session_id` field)
- [ ] Signed cookie is still set correctly in the response
- [ ] Existing HTML tests unchanged

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by security-sentinel (High), architecture-strategist, kieran-rails-reviewer.
