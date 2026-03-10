---
status: pending
priority: p2
issue_id: "244"
tags: [code-review, rails, routes, onboarding, dead-code]
dependencies: []
---

# Route Constraint Allows Step 3, Orphaned `_step_3.html.erb` Exists

## Problem Statement

The routes file has `constraints: { step: /[1-3]/ }` for both `step` and `skip` routes, but the wizard was rewritten to 2 steps. `_step_3.html.erb` still exists and contains working links (`onboarding_skip_path(3)`). The `current_step` method only handles steps 1–2. These three things are inconsistent: the route says step 3 is valid, the controller makes it unreachable, the view exists. Future developers cannot tell if step 3 is planned, deprecated, or accidentally broken.

## Findings

- `config/routes.rb:48` — `get "step/:step", constraints: { step: /[1-3]/ }`
- `config/routes.rb:51` — `get "skip/:step", constraints: { step: /[1-3]/ }`
- `app/views/onboarding/_step_3.html.erb` — exists, has a "Back to step 2" link and "Skip for now → skip/3"
- `onboarding_controller.rb:78` — `step.between?(1, 2) ? step : (redirect_to ... and return 1)` — step 3 redirects to step 1
- Agent-native reviewer: "a GET /onboarding/step/3 would get redirected to step 1 without any clear explanation"
- Architecture reviewer: "route allows it, controller blocks it, view exists — worst of all options"

## Proposed Solutions

### Option 1: Tighten constraint to `[1-2]`, delete `_step_3.html.erb` (Recommended)

**Approach:**
- Change `constraints: { step: /[1-3]/ }` to `constraints: { step: /[12]/ }` for both routes
- Delete `app/views/onboarding/_step_3.html.erb`
- Remove the `else` branch in `skip` that handles unknown steps (or keep a simple `redirect_to dashboard_path` fallback)

**Pros:**
- Eliminates dead code and confusion
- Routes accurately reflect the 2-step implementation

**Cons:**
- Deletes a file (recoverable from git if step 3 ever needed)

**Effort:** 10 minutes

**Risk:** Low

---

### Option 2: Add a comment explaining step 3 is a future placeholder

**Approach:** Add `# Step 3 is a placeholder for future use` comments in routes.rb and `_step_3.html.erb`.

**Pros:** Preserves the file for future use

**Cons:** Doesn't fix the controller inconsistency; still confusing

**Effort:** 5 minutes

**Risk:** Low

## Recommended Action

Option 1. Step 3 has no planned existence. Delete it.

## Technical Details

**Affected files:**
- `config/routes.rb:48,51` — constraint change
- `app/views/onboarding/_step_3.html.erb` — delete
- `app/controllers/onboarding_controller.rb:78` — simplify fallback if desired

## Acceptance Criteria

- [ ] Route constraints use `/[12]/` not `/[1-3]/`
- [ ] `_step_3.html.erb` is deleted
- [ ] `GET /onboarding/step/3` returns 404 (no route match)
- [ ] `bin/rails test` passes

## Work Log

### 2026-03-10 — Code Review Discovery

**By:** Claude Code (ce:review)

**Actions:** Flagged by Rails reviewer, architecture reviewer, and agent-native reviewer independently.
