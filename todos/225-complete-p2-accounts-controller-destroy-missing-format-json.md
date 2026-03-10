---
status: pending
priority: p2
issue_id: "225"
tags: [api, rails, agent-native, code-review]
dependencies: []
---

# AccountsController#destroy Missing format.json — Violates Documented API Convention and Silently Breaks JSON Clients

## Problem Statement

The `ApplicationController` includes an explicit comment: "Every resource action that creates/modifies data must support format.json so agents can call endpoints programmatically." Every other mutating controller (`SymptomLogsController`, `PeakFlowReadingsController`, `HealthEventsController`, `ProfilesController`, `SessionsController`) has `respond_to` blocks with `format.json`. `AccountsController#destroy` has none — a JSON client receives an HTML 302 redirect, not a meaningful response.

The omission is either (a) an accidental gap violating the convention, or (b) an intentional "human-only" gate. If (b), the intent must be documented and enforced properly (return 403 for JSON clients), not left as a silent broken redirect.

## Findings

**Flagged by:** architecture-strategist, agent-native-reviewer

**Location:**
- `app/controllers/accounts_controller.rb` — `#destroy` action has no `respond_to` block

**Observed behaviour:** A JSON client sending `DELETE /account.json` with a valid session and `confirmation=DELETE` receives an HTML 302 redirect — neither a 204 nor a 403.

## Proposed Solutions

### Option A — Add JSON Support (Recommended — follows convention)

Add a `respond_to` block to `#destroy`:

```ruby
respond_to do |format|
  format.html { redirect_to root_path, notice: "..." }
  format.json { head :no_content }
end
```

On failure:

```ruby
format.json { render json: { error: "Account confirmation did not match." }, status: :unprocessable_entity }
```

**Pros:** Consistent with every other mutating controller; agents can automate account teardown in test environments.
**Cons:** Irreversible action is now callable without a browser UI — requires clear documentation.
**Effort:** Small
**Risk:** Low (action already requires authenticated session + correct confirmation string)

### Option B — Explicit Human-Only Gate

Add a guard at the top of `#destroy`:

```ruby
if request.format.json?
  render json: { error: "Account deletion requires browser-based authentication" }, status: :forbidden
  return
end
```

Document the decision in a comment above the guard.

**Pros:** Prevents any non-browser invocation; explicit and intentional.
**Cons:** Diverges from codebase-wide `respond_to` convention; requires documentation to avoid confusion.
**Effort:** Small
**Risk:** None

## Recommended Action

Option A unless the team has explicitly decided account deletion is a human-only operation. If Option B is chosen, add a comment documenting the intentional deviation from the API convention.

## Technical Details

**Affected files:**
- `app/controllers/accounts_controller.rb`

**Acceptance Criteria:**
- [ ] JSON clients receive either a meaningful response or an explicit 403 (not a silent HTML redirect)
- [ ] Decision (human-only vs agent-accessible) is documented in a comment in the controller
- [ ] If JSON supported: `DELETE /account.json` with `confirmation=DELETE` returns 204
- [ ] If JSON blocked: `DELETE /account.json` returns 403 with JSON error body

## Work Log

- 2026-03-10: Identified by architecture-strategist and agent-native-reviewer in Phase 16 code review.

## Resources

- Rails `respond_to` docs: https://api.rubyonrails.org/classes/ActionController/MimeResponds.html#method-i-respond_to
