---
status: complete
priority: p1
issue_id: "033"
tags: [code-review, authentication, agent-native, api, json]
dependencies: []
---

# `request_authentication` Returns HTML Redirect for JSON Requests — Agents Cannot Detect Auth Failure

## Problem Statement

`Authentication#request_authentication` always redirects to the login form regardless of request format. Any JSON API client (agent or mobile app) that presents an expired or missing session to a protected resource receives a `302 → /session/new` HTML response instead of a machine-readable `401 Unauthorized`. This makes it impossible for agents to detect authentication failure programmatically and means the entire JSON API surface silently degrades to returning redirects on auth failure.

## Findings

**Flagged by:** agent-native-reviewer (Critical Issue 1)

**Location:** `app/controllers/concerns/authentication.rb`, lines 29-32

```ruby
def request_authentication
  session[:return_to_after_authenticating] = request.url
  redirect_to new_session_path
end
```

**Impact:**
- An agent that successfully calls `POST /session` and receives a `{ session_id: 42 }` response cannot use that integer as a credential (it must read the `Set-Cookie` header). If its session expires, subsequent requests to any protected endpoint silently return `302` to the login form.
- No `respond_to` block means JSON clients can never distinguish "unauthenticated" from "server error" or "moved resource".
- This breaks the stated architectural policy that every data action must support JSON for agents.

## Proposed Solutions

### Solution A: Add `respond_to` to `request_authentication` (Recommended)
```ruby
def request_authentication
  respond_to do |format|
    format.html do
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end
    format.json { render json: { error: "Authentication required" }, status: :unauthorized }
  end
end
```
- **Pros:** Standard Rails pattern. `return_to` stored only for HTML clients (meaningless for JSON). Agents get `401` with structured error.
- **Cons:** None.
- **Effort:** Small
- **Risk:** Low

### Solution B: Check `request.format.json?` inline
```ruby
def request_authentication
  if request.format.json?
    render json: { error: "Authentication required" }, status: :unauthorized
  else
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_path
  end
end
```
- **Pros:** Slightly more explicit.
- **Cons:** Less idiomatic than `respond_to`.
- **Effort:** Small
- **Risk:** Low

## Recommended Action

Solution A. This is the minimal fix to make the JSON auth surface functional for agents.

## Technical Details

- **File:** `app/controllers/concerns/authentication.rb`
- **Method:** `request_authentication` (called as `before_action :require_authentication`)

## Acceptance Criteria

- [ ] `GET /symptom_logs` with `Accept: application/json` and no session cookie returns `401 { "error": "Authentication required" }`
- [ ] `GET /symptom_logs` with `Accept: text/html` and no session cookie still redirects to `/session/new`
- [ ] `return_to_after_authenticating` is only set for HTML format requests

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by agent-native-reviewer as Critical Issue 1.
