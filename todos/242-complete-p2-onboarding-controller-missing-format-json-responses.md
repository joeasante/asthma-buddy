---
status: pending
priority: p2
issue_id: "242"
tags: [code-review, rails, agent-native, json, onboarding]
dependencies: []
---

# OnboardingController Missing `format.json` Responses

## Problem Statement

`ApplicationController` contains an explicit comment requiring every data-mutating action to support `format.json` so agents can call endpoints programmatically. `OnboardingController` violates this for all 4 data-mutating actions (`submit_1`, `submit_2`, `skip`, and the dashboard guard). A newly registered user whose account was created by an agent is permanently unable to reach the dashboard via an agent client — the `check_onboarding` guard keeps redirecting to `/onboarding/step/1`, which has no JSON interface to complete.

## Findings

- `ApplicationController` lines 15-17 state: "Every resource action that creates/modifies data must support `format.json` so agents can call endpoints programmatically"
- `submit_1`, `submit_2`, `skip` all call `redirect_to` unconditionally — no `respond_to` block
- `DashboardController#check_onboarding` issues HTML redirect for JSON requests
- Agent-native reviewer: "0 of 4 data-mutating onboarding actions return machine-readable JSON responses" — "NEEDS WORK"
- Compare `ProfilesController#update_personal_best` which already implements the correct pattern with `format.json { render json: { value: ... }, status: :created }`
- Also: hidden field defaults (`starting_dose_count: 200`) in `_step_2.html.erb` are invisible to non-HTML clients

## Proposed Solutions

### Option 1: Add `respond_to` blocks following existing ProfilesController pattern (Recommended)

**Approach:** Mirror `ProfilesController#update_personal_best`. On success, return JSON with updated flag states. On failure, return `{ errors: [...] }` with 422.

```ruby
def submit_1
  value = params.dig(:personal_best_record, :value).to_i
  if value.between?(100, 900)
    # ... existing logic wrapped in transaction ...
    respond_to do |format|
      format.html { redirect_to onboarding_step_path(2) }
      format.json { render json: { onboarding_personal_best_done: true, next_step: 2 }, status: :ok }
    end
  else
    respond_to do |format|
      format.html { render :show, status: :unprocessable_entity }
      format.json { render json: { errors: ["Value must be between 100 and 900 L/min"] }, status: :unprocessable_entity }
    end
  end
end
```

Also make `check_onboarding` in `DashboardController` JSON-aware:
```ruby
def check_onboarding
  return if Current.user.onboarding_complete?
  respond_to do |format|
    format.html { redirect_to onboarding_step_path(1) }
    format.json { render json: { error: "onboarding_required", next_step: 1 }, status: :forbidden }
  end
end
```

Also move `starting_dose_count: 200` default from the hidden field in `_step_2.html.erb` into the controller's `@medication` initialization so it's visible to all clients.

**Pros:**
- Satisfies stated project convention
- Enables agent-native onboarding flows
- Consistent with all other data controllers

**Cons:**
- More code in the controller
- Requires controller test updates for JSON format assertions

**Effort:** 1 hour

**Risk:** Low

---

### Option 2: Document onboarding as HTML-only with a comment

**Approach:** Add a comment to `OnboardingController` explicitly noting it is HTML-only and exempt from the JSON convention, then update `ApplicationController` comment accordingly.

**Pros:** Less code

**Cons:** Violates the project's own stated convention; blocks agent-native new user flows

**Effort:** 5 minutes

**Risk:** Low code risk, high architectural risk

## Recommended Action

Option 1. The project convention is explicit and the `ProfilesController` pattern already exists to follow.

## Technical Details

**Affected files:**
- `app/controllers/onboarding_controller.rb` — all 4 actions
- `app/controllers/dashboard_controller.rb` — `check_onboarding`
- `app/views/onboarding/_step_2.html.erb` — move `starting_dose_count` default to controller
- `test/controllers/onboarding_controller_test.rb` — add JSON format tests

## Acceptance Criteria

- [ ] `submit_1`, `submit_2`, `skip` all have `respond_to` blocks with `format.json`
- [ ] `check_onboarding` returns `{ error: "onboarding_required" }` with 422/403 for JSON requests
- [ ] `starting_dose_count: 200` default is set on `@medication` in `show` action, not only in the hidden field
- [ ] `bin/rails test` passes

## Work Log

### 2026-03-10 — Code Review Discovery

**By:** Claude Code (ce:review)

**Actions:** Found by agent-native reviewer. ProjectConvention violation confirmed in ApplicationController.
