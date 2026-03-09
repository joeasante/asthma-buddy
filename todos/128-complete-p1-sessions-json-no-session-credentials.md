---
status: pending
priority: p1
issue_id: "128"
tags: [code-review, security, api, authentication, agent-native]
dependencies: []
---

# `sessions#create` JSON Returns No Session Credentials

## Problem Statement

A JSON `POST /session` returns `{ "message": "Signed in." }` with a `Set-Cookie` header, but no session identifier in the response body. Agents using HTTP clients without a cookie jar (most simple HTTP libraries: Python `requests`, Ruby `Net::HTTP`, JavaScript `fetch` without credentials) will authenticate successfully and then get 401 on every subsequent request. This is the single highest-severity agent-native parity gap — it blocks all authenticated API usage.

Flagged by: agent-native-reviewer (critical blocker).

## Findings

**File:** `app/controllers/sessions_controller.rb`, lines 26–28

```ruby
format.json { render json: { message: "Signed in." }, status: :created }
```

`start_new_session_for` writes the session ID to a signed cookie. For browsers, the cookie is sent automatically. For stateless HTTP agents, the `Set-Cookie` header must be read and stored, then replayed as a `Cookie` header on every subsequent request. Most agent frameworks do not do this automatically.

The root issue: there is no token-based auth path. Every authenticated action requires the session cookie.

## Proposed Solutions

**Solution A — Document cookie requirement explicitly and test it (short-term):**

Add a comment in the controller and API docs that JSON clients MUST preserve and replay the `Set-Cookie` session cookie. Add an integration test using `Net::HTTP` directly (no cookie jar) to verify the current behavior and catch regressions.

- Pros: No code change, honest documentation
- Cons: Still broken for naive HTTP clients; doesn't actually fix the gap
- Effort: Small

**Solution B — Return session token in JSON response body (medium-term):**
```ruby
format.json do
  render json: {
    message: "Signed in.",
    session_id: Current.session.id
  }, status: :created
end
```
Agents send `Cookie: session_id=<signed_value>` by reconstructing the cookie. This is fragile because the cookie is signed — agents would need to know the signing format.

- Pros: Quick
- Cons: Requires agents to manually construct a signed cookie; still cookie-based
- Effort: Small

**Solution C — Add Bearer token authentication (long-term, recommended):**

Create a `PersonalAccessToken` model. `resume_session` checks `Authorization: Bearer <token>` before falling back to cookies. Agents authenticate once with credentials, receive a Bearer token, and use it for all subsequent requests.

```ruby
# authentication.rb
def resume_session
  if (token = bearer_token_from_header)
    Current.session = Session.find_by_token(token)
  else
    Current.session = Session.find_by(id: cookies.signed[:session_id])
  end
end
```

- Pros: Industry standard, stateless, clean agent-native pattern
- Cons: Requires new model, migration, controller changes; larger scope
- Effort: Large

## Recommended Action

Short-term: Solution B (return session ID in JSON response body with documented cookie usage). Long-term: Solution C (Bearer token). These are not mutually exclusive — implement B now and track C as a future enhancement.

## Technical Details

- **Affected files:** `app/controllers/sessions_controller.rb`, `app/controllers/concerns/authentication.rb`
- **Downstream impact:** Until this is fixed, all other agent-native JSON endpoints are effectively unreachable for stateless clients

## Acceptance Criteria

- [ ] `POST /session` JSON response includes a usable credential (token or session ID)
- [ ] Agent can authenticate and make subsequent authenticated requests without cookie jar
- [ ] Existing browser session flow is unaffected
- [ ] Test: JSON sign-in → use returned credential → `GET /symptom_logs` with `Accept: application/json` → 200

## Work Log

- 2026-03-08: Identified by agent-native-reviewer as most critical gap blocking all downstream API usage
