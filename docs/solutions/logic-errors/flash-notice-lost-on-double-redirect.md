---
title: Flash notice not displayed after skipping onboarding step 2 due to incomplete onboarding flag updates
problem_type: logic-errors
component: OnboardingController, DashboardController, User model
symptoms:
  - Flash notice "You can complete setup any time from Settings." does not appear after user skips step 2
  - User is redirected back to onboarding step 1 instead of being shown the dashboard
  - Second redirect from a before_action guard discards the pending flash message
severity: medium
tags:
  - flash-messages
  - redirect-chain
  - before-action-guard
  - onboarding-flow
  - state-management
rails_version: 8.1.2
ruby_version: 4.0.1
resolved: true
date_resolved: 2026-03-10
related:
  - docs/solutions/ui-bugs/turbo-stream-flash-messages-and-frame-preservation.md
---

# Flash Notice Lost on Double Redirect

Flash notices set in one redirect are silently discarded when a `before_action` guard in the destination controller issues a second redirect before the user's browser renders.

## Symptom

After clicking "Skip this step" on onboarding step 2, the user lands on the dashboard with no flash notice. Expected: "You can complete setup any time from Settings."

## Root Cause Analysis

The flash notice disappeared because of a **cascade of redirect guards** that consumed the notice before it reached the user.

**Redirect chain:**

```
User clicks "Skip Step 2"
  ↓
OnboardingController#skip → redirect_to dashboard_path, notice: "..."
  ↓ (browser follows 302)
DashboardController#index — before_action :check_onboarding fires
  ↓
onboarding_complete? returns FALSE (only one flag was set)
  ↓
check_onboarding → redirect_to onboarding_step_path(1)  ← SECOND REDIRECT
  ↓
Flash notice discarded — user sees onboarding step 1 with no message
```

The `skip` action for step 2 only set one of the two required flags:

```ruby
# BEFORE (broken)
when 2
  Current.user.update!(onboarding_medication_done: true)  # missing onboarding_personal_best_done!
  redirect_to dashboard_path, notice: "You can complete setup any time from Settings."
```

`User#onboarding_complete?` requires **both** flags:

```ruby
def onboarding_complete?
  onboarding_personal_best_done? && onboarding_medication_done?
end
```

If the user had also skipped step 1, `onboarding_personal_best_done` was still `false`, causing `check_onboarding` to reject the dashboard request and redirect again — discarding the flash.

## The Fix

Set both flags when skipping step 2, satisfying `onboarding_complete?` before the redirect fires:

```ruby
# AFTER (fixed)
when 2
  Current.user.update!(onboarding_personal_best_done: true, onboarding_medication_done: true)
  respond_to do |format|
    format.html { redirect_to dashboard_path, notice: "You can complete setup any time from Settings." }
    format.json { render json: { onboarding_personal_best_done: true, onboarding_medication_done: true }, status: :ok }
  end
```

**Why this works:** With both flags true, `onboarding_complete?` returns `true`, `check_onboarding` returns early, no second redirect fires, and the flash notice survives to the dashboard.

**Key insight:** Skipping step 2 implies step 1 is also "done" from a UX perspective — the user has chosen not to complete either onboarding step. Setting both flags reflects this intent.

## Test Coverage

Two tests added to `test/controllers/onboarding_controller_test.rb`:

```ruby
test "PATCH skip step 2 after completing step 1 — flash notice present" do
  sign_in_as users(:new_user)
  users(:new_user).update!(onboarding_personal_best_done: true)
  patch onboarding_skip_path(2)
  assert_redirected_to dashboard_path
  follow_redirect!
  assert_equal "You can complete setup any time from Settings.", flash[:notice]
end

test "PATCH skip both steps — both flags true and flash notice survives to dashboard" do
  sign_in_as users(:new_user)
  patch onboarding_skip_path(2)
  assert users(:new_user).reload.onboarding_personal_best_done?
  assert users(:new_user).reload.onboarding_medication_done?
  follow_redirect!
  assert_equal "You can complete setup any time from Settings.", flash[:notice]
end
```

The `follow_redirect!` + `assert_equal flash[:notice]` pattern is the key — it catches double-redirect flash loss that a simple `assert_redirected_to` would miss.

## Prevention

### The General Rule

> **When using `redirect_to path, notice:`, verify the destination's `before_action` guards won't redirect again.**

Checklist:
1. Identify the target path of your `redirect_to`
2. Find all `before_action` guards on the destination controller
3. Trace each guard's condition
4. Ensure the condition will be `true` after your action runs — if not, the guard will redirect again and discard your flash
5. Write a test with `follow_redirect!` to verify flash survives

### Two Fix Approaches

**Option A — Satisfy the guard condition before redirecting (preferred)**

Ensure the state your action sets is sufficient for the destination's guards to pass. Used in this fix.

```ruby
# Set ALL flags required by the destination guard
Current.user.update!(onboarding_personal_best_done: true, onboarding_medication_done: true)
redirect_to dashboard_path, notice: "..."
```

**Option B — Forward flash in the guard redirect (fallback)**

If you can't control the guard condition, carry the flash forward explicitly:

```ruby
def check_onboarding
  return if Current.user.onboarding_complete?
  respond_to do |format|
    format.html { redirect_to onboarding_step_path(1), flash: flash.to_hash }
  end
end
```

Option A is cleaner — Option B masks the underlying issue.

### Detection Pattern

```ruby
# Issue the request that redirects with flash
patch some_path(params)

# Assert initial redirect target
assert_redirected_to expected_path

# Follow the redirect — this triggers the destination's before_actions
follow_redirect!

# Assert flash survived to the final destination
assert_equal "Expected message", flash[:notice]
```

If a guard redirects a second time, `flash[:notice]` will be `nil` here — catching the bug.

## Code Locations (asthma-buddy)

| File | Lines | Role |
|------|-------|------|
| `app/controllers/onboarding_controller.rb` | 89–94 | Sets both flags, redirects with notice |
| `app/controllers/dashboard_controller.rb` | 103–109 | `check_onboarding` guard — evaluates `onboarding_complete?` |
| `app/models/user.rb` | 35–37 | `onboarding_complete?` predicate |
| `test/controllers/onboarding_controller_test.rb` | 98–114 | Regression tests for both skip scenarios |

## See Also

- [Flash messages and Turbo Streams](../ui-bugs/turbo-stream-flash-messages-and-frame-preservation.md) — related flash persistence issues with Hotwire
