---
status: pending
priority: p2
issue_id: "292"
tags: [code-review, rails, onboarding, regression, wizard]
dependencies: []
---

# redirect_if_step1_done removed — mid-wizard users can re-submit step 1

## Problem Statement
`OnboardingController` previously had a `redirect_if_step1_done` before_action that redirected users away from `/onboarding/step/1` if `onboarding_personal_best_done?` was already true. This was removed in the dev branch. A user who completed step 1 but not step 2 can now navigate back to step 1 and re-submit, creating a duplicate `PersonalBestRecord`. The `redirect_if_onboarding_complete` guard (which remains) only fires when both flags are true, so mid-wizard users are unprotected.

## Findings
**Flagged by:** architecture-strategist

**File:** `app/controllers/onboarding_controller.rb`

Removed code:
```ruby
before_action :redirect_if_step1_done, only: :show

def redirect_if_step1_done
  redirect_to onboarding_step_path(2) if params[:step].to_i == 1 && Current.user.onboarding_personal_best_done?
end
```

No test covers the scenario: user with `onboarding_personal_best_done: true` but `onboarding_medication_done: false` accessing step 1.

## Proposed Solutions

### Option A — Restore the before_action (Recommended if removal was unintentional)
Restore `redirect_if_step1_done` as it was. Add a test asserting the redirect.
**Effort:** Small. **Risk:** Low.

### Option B — Guard at submit_1 level (if re-entry is intentional)
If users should be allowed to revisit step 1 to correct their personal best, guard `submit_1` against creating duplicates:
```ruby
def submit_1
  @personal_best = Current.user.personal_best_records.first_or_initialize
  ...
end
```
Document the intent clearly.
**Effort:** Small. **Risk:** Low.

## Recommended Action

## Technical Details
- **File:** `app/controllers/onboarding_controller.rb`
- **Impact:** Mid-wizard users can re-enter step 1 and create duplicate PersonalBestRecord entries

## Acceptance Criteria
- [ ] Either: redirect_if_step1_done is restored and tested, OR
- [ ] submit_1 is guarded against duplicate PersonalBestRecord creation and the intentional re-entry is documented
- [ ] Test covering: user with onboarding_personal_best_done=true accessing step 1

## Work Log
- 2026-03-12: Code review finding — architecture-strategist

## Resources
- Branch: dev
