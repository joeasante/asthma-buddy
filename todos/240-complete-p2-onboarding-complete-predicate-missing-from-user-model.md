---
status: pending
priority: p2
issue_id: "240"
tags: [code-review, rails, dry, onboarding, user-model]
dependencies: []
---

# `onboarding_complete?` Predicate Missing from User Model

## Problem Statement

The identical boolean expression `onboarding_personal_best_done? && onboarding_medication_done?` appears in both `OnboardingController#redirect_if_onboarding_complete` and `DashboardController#check_onboarding`. The knowledge of what constitutes "onboarding complete" belongs on the `User` domain model, not duplicated across controller infrastructure. If a third onboarding step is ever added, both controllers must be updated manually.

## Findings

- `onboarding_controller.rb:67` — `Current.user.onboarding_personal_best_done? && Current.user.onboarding_medication_done?`
- `dashboard_controller.rb:99` — same expression
- `app/models/user.rb` — no `onboarding_complete?` method exists
- Simplicity reviewer: "The predicate `onboarding_complete?` belongs on the `User` model — one line, one place to change"
- Architecture reviewer: "The single change with the best ratio of value to effort in this entire review"

## Proposed Solutions

### Option 1: Add `onboarding_complete?` to User model (Recommended)

**Approach:**

Add to `app/models/user.rb`:
```ruby
def onboarding_complete?
  onboarding_personal_best_done? && onboarding_medication_done?
end
```

Then simplify both controllers:
```ruby
# OnboardingController
redirect_to dashboard_path if Current.user.onboarding_complete?

# DashboardController
redirect_to onboarding_step_path(1) unless Current.user.onboarding_complete?
```

Add test to `test/models/user_test.rb`.

**Pros:**
- Single source of truth for the predicate
- Both guards become a single readable line
- Future-proof — add step 3 by updating one method

**Cons:**
- None meaningful

**Effort:** 15 minutes

**Risk:** Low

## Recommended Action

Option 1. Add the method to User, update both controller guards, add model test.

## Technical Details

**Affected files:**
- `app/models/user.rb` — add method
- `app/controllers/onboarding_controller.rb:67` — simplify guard
- `app/controllers/dashboard_controller.rb:99` — simplify guard
- `test/models/user_test.rb` — add test

## Acceptance Criteria

- [ ] `User#onboarding_complete?` method exists and returns `true` only when both flags are `true`
- [ ] Both controller guards use `Current.user.onboarding_complete?`
- [ ] `test/models/user_test.rb` has at least 3 cases: neither flag, one flag, both flags
- [ ] `bin/rails test` passes

## Work Log

### 2026-03-10 — Code Review Discovery

**By:** Claude Code (ce:review)

**Actions:** Flagged by simplicity reviewer and architecture reviewer as highest-value simplification.
