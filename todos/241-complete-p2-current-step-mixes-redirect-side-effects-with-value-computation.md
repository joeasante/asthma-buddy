---
status: pending
priority: p2
issue_id: "241"
tags: [code-review, rails, code-quality, onboarding]
dependencies: [240]
---

# `current_step` Mixes Redirect Side-Effects with Value Computation

## Problem Statement

`OnboardingController#current_step` is a private helper that returns an integer, but it also secretly issues HTTP redirects via `and return`. A caller doing `@step = current_step` does not expect that call to possibly redirect and return early — this is surprising action at a distance. The `and return` pattern inside a value-returning method is not idiomatic Rails; the convention is to issue redirects from `before_action` guards.

## Findings

- `onboarding_controller.rb:72-79` — `current_step` contains two `redirect_to ... and return N` calls
- The one-liner `step.between?(1, 2) ? step : (redirect_to(onboarding_step_path(1)) and return 1)` is particularly opaque
- Rails reviewer: "FAIL — the `and return` pattern inside a private helper that returns a value is not acceptable"
- Simplicity reviewer: "Makes a value-returning method secretly issue HTTP redirects, which will confuse any future developer"
- Pattern reviewer: "Functionally correct, but a `before_action` would be more idiomatic"

## Proposed Solutions

### Option 1: Extract redirect to a dedicated `before_action` (Recommended)

**Approach:**

```ruby
# Add to before_action chain (after redirect_if_onboarding_complete):
before_action :redirect_if_step1_done, only: :show

# Simplify current_step to a pure value method:
def current_step
  step = params[:step].to_i
  step.between?(1, 2) ? step : 1
end

# New before_action:
def redirect_if_step1_done
  redirect_to onboarding_step_path(2) if params[:step].to_i == 1 && Current.user.onboarding_complete?
end
```

Note: after #240 is resolved, `Current.user.onboarding_personal_best_done?` becomes `Current.user.onboarding_complete?` — but the step 1 redirect should check only `onboarding_personal_best_done?` specifically (user has done step 1 but not step 2 yet).

**Pros:**
- `current_step` is a pure value-returning method
- Redirects live where Rails expects them (before_actions)
- `and return` trick disappears entirely

**Cons:**
- Adds one more `before_action` to the chain

**Effort:** 20 minutes

**Risk:** Low

---

### Option 2: Inline redirect logic into `show` action directly

**Approach:** Move the step-routing logic into the `show` action body with explicit `and return` at the action level (which is the one accepted Rails use of this pattern).

**Pros:** Fewer methods, slightly more readable execution path

**Cons:** `show` becomes longer

**Effort:** 15 minutes

**Risk:** Low

## Recommended Action

Option 1. Dependency on #240 for the `onboarding_complete?` method.

## Technical Details

**Affected files:**
- `app/controllers/onboarding_controller.rb:72-79`

## Acceptance Criteria

- [ ] `current_step` contains no `redirect_to` calls — returns an integer only
- [ ] Step-routing redirects live in a `before_action` or in the `show` action body
- [ ] No `and return N` in any private helper method
- [ ] `bin/rails test` passes

## Work Log

### 2026-03-10 — Code Review Discovery

**By:** Claude Code (ce:review)
