---
status: pending
priority: p3
issue_id: "031"
tags: [code-review, agent-native, authentication, api, architecture]
dependencies: []
---

# Authentication Has No JSON Path — Agents and API Clients Cannot Sign In

## Problem Statement

`SessionsController#create` has no `respond_to` block. An API client or agent posting credentials receives an HTML redirect response, not a session token it can use for subsequent requests. The `application_controller.rb` comment explicitly states that every mutating action must support `format.json` — but the auth controller predates that policy and was never updated. This is a pre-existing gap, not introduced by the current changeset.

## Findings

**Flagged by:** agent-native-reviewer

**Location:** `app/controllers/sessions_controller.rb`

```ruby
# Current — no JSON path
def create
  if user = User.authenticate_by(params.permit(:email_address, :password))
    if user.email_verified_at.present?
      start_new_session_for user
      redirect_to after_authentication_url   # HTML only — no JSON response
    ...
```

**Scope of the gap:**
- 0 of 4 auth mutations have JSON response paths (sign in, sign out, sign up, password reset)
- Only 1 of 7 total capabilities is agent-accessible (email verification via token GET)
- `application_controller.rb` declares the intent: _"Non-browser clients (agents, API callers, curl) request JSON and must not be rejected"_ — but the implementation doesn't match

**Current impact:** Low (app has no health data features yet). Becomes High the moment symptom logging or peak flow recording is implemented — agents would be locked out of all data creation.

## Proposed Solutions

### Solution A: Add `respond_to` blocks to auth controllers with session ID in JSON response

```ruby
# sessions_controller.rb
def create
  if user = User.authenticate_by(params.permit(:email_address, :password))
    if user.email_verified_at.present?
      start_new_session_for user
      respond_to do |format|
        format.html { redirect_to after_authentication_url }
        format.json { render json: { session_id: Current.session.id }, status: :created }
      end
```

Agent callers extract `session_id` from the response and pass it as a `Cookie: session_id=<signed_value>` header (or as `X-Session-Token` with a corresponding server-side lookup) on subsequent requests.

- **Effort:** Medium (4 controllers to update + server-side token lookup)
- **Risk:** Low

### Solution B: Add API token authentication alongside cookie auth

Generate `User#api_token` on creation. Agents authenticate with `Authorization: Bearer <token>` header, bypassing the session cookie model entirely.
- **Pros:** Clean separation between browser (cookies) and agent (tokens).
- **Cons:** Larger scope — token lifecycle management, rotation, scoping.
- **Effort:** Large
- **Risk:** Medium

### Solution C: Defer until health data features are built

Do nothing now. Add JSON auth paths in the same phase that adds symptom/peak-flow controllers, building them correctly from the start.
- **Pros:** No premature abstraction — auth JSON paths are most useful alongside protected resources.
- **Cons:** The gap remains; any test tooling that needs to sign in programmatically hits a wall.
- **Effort:** None (deferred)
- **Risk:** Low (pre-existing gap, no regression)

## Recommended Action

Solution C for now — this is a pre-existing gap and the app currently has no health data to protect. When Phase 2 health tracking features are built, implement Solution A (session ID in JSON response) alongside the first protected resource controller.

## Technical Details

- **Affected files:** `app/controllers/sessions_controller.rb`, `app/controllers/registrations_controller.rb`, `app/controllers/passwords_controller.rb`
- **Reference:** `app/controllers/application_controller.rb` comment on non-browser clients
- **Priority escalation trigger:** When any controller requires `authenticate` before_action

## Acceptance Criteria

- [ ] `POST /session` with `Accept: application/json` returns `{ session_id: "..." }` and status 201
- [ ] `DELETE /session` with JSON accept returns 200
- [ ] `POST /registration` with JSON accept returns user info and 201
- [ ] Existing browser flows unaffected
- [ ] Agent can sign in, receive session ID, and make authenticated requests

## Work Log

- 2026-03-06: Identified by agent-native-reviewer during /ce:review of foundation phase changes. Recommended to defer until Phase 2 health tracking.
