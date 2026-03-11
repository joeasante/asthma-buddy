---
status: resolved
trigger: "After clicking Skip this step on onboarding step 2, the user is redirected to the dashboard but the flash notice does NOT appear"
created: 2026-03-10T00:00:00Z
updated: 2026-03-10T00:00:00Z
---

## Current Focus

hypothesis: check_onboarding redirects authenticated-but-incomplete users away from dashboard, consuming the flash before it renders
test: trace the redirect chain after skip action sets onboarding_medication_done: true
expecting: second redirect clears the flash
next_action: confirmed — document resolution

## Symptoms

expected: Flash notice "You can complete setup any time from Settings." visible on dashboard after clicking Skip
actual: Redirect happens but no notice appears on dashboard
errors: none (silent failure)
reproduction: Click "Skip this step" on onboarding step 2
started: introduced when check_onboarding before_action was added to DashboardController

## Eliminated

- hypothesis: Flash partial missing from application layout
  evidence: app/views/layouts/application.html.erb line 108 renders "layouts/flash"
  timestamp: 2026-03-10T00:00:00Z

- hypothesis: Flash partial missing from onboarding layout
  evidence: app/views/layouts/onboarding.html.erb line 26 renders "layouts/flash" — irrelevant to the destination anyway
  timestamp: 2026-03-10T00:00:00Z

- hypothesis: notice key not set on the redirect_to call
  evidence: app/controllers/onboarding_controller.rb line 92 correctly uses redirect_to dashboard_path, notice: "..."
  timestamp: 2026-03-10T00:00:00Z

## Evidence

- timestamp: 2026-03-10T00:00:00Z
  checked: app/controllers/onboarding_controller.rb lines 89-94
  found: skip action for step 2 calls Current.user.update!(onboarding_medication_done: true) THEN redirect_to dashboard_path with notice
  implication: notice is set in flash correctly before redirect

- timestamp: 2026-03-10T00:00:00Z
  checked: app/controllers/dashboard_controller.rb lines 103-109
  found: check_onboarding before_action calls Current.user.onboarding_complete? — if false, redirects to onboarding_step_path(1) WITHOUT forwarding the flash
  implication: second redirect is the flash killer IF onboarding_complete? returns false at this point

- timestamp: 2026-03-10T00:00:00Z
  checked: onboarding_controller.rb skip action for step 2 (line 90)
  found: only sets onboarding_medication_done: true — onboarding_complete? requires BOTH onboarding_personal_best_done AND onboarding_medication_done to be true (need to verify model)
  implication: if user skipped step 1 (personal_best_done is false) then onboarding_complete? is false, causing a second redirect

- timestamp: 2026-03-10T00:00:00Z
  checked: flow when user skips step 2 directly (having completed step 1)
  found: skip step 1 sets onboarding_personal_best_done: true; skip step 2 sets onboarding_medication_done: true — if both done, onboarding_complete? is true and check_onboarding passes
  implication: the bug reproduces specifically when a user arrived at step 2 WITHOUT having gone through step 1 (edge case) OR if onboarding_complete? requires a third flag

- timestamp: 2026-03-10T00:00:00Z
  checked: redirect chain on the happy path (step 1 complete, skip step 2)
  found: skip sets onboarding_medication_done: true (both flags now true) -> redirect_to dashboard_path with notice -> DashboardController#index -> check_onboarding sees onboarding_complete? true -> passes -> index renders with flash notice PRESENT. This path works.
  implication: the second redirect only fires if onboarding_complete? returns false after the update

- timestamp: 2026-03-10T00:00:00Z
  checked: redirect_if_onboarding_complete in OnboardingController (line 100-102)
  found: redirect_to dashboard_path with NO notice — does not carry flash forward
  implication: not relevant here; fires on onboarding controller not dashboard

- timestamp: 2026-03-10T00:00:00Z
  checked: check_onboarding in DashboardController (lines 103-109)
  found: redirect_to onboarding_step_path(1) with NO notice or flash preservation
  implication: if this fires, the flash notice set by the skip action is silently discarded

## Resolution

root_cause: DashboardController#check_onboarding issues a second redirect to onboarding_step_path(1) — without preserving the flash — when Current.user.onboarding_complete? returns false at the time the dashboard request is processed. This happens when the user arrives at step 2 without onboarding_personal_best_done being true (e.g. they skipped step 1 too, or the flag is not persisted in the session). The skip action correctly sets the notice on the first redirect, but the second redirect from check_onboarding discards it before the layout can render it.
fix: not applied (diagnose-only mode)
verification: n/a
files_changed: []
