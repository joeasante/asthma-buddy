---
phase: 17-onboarding-flow
plan: gap-01
type: execute
wave: 1
depends_on: []
files_modified:
  - app/controllers/onboarding_controller.rb
  - test/controllers/onboarding_controller_test.rb
autonomous: true
gap_closure: true

must_haves:
  truths:
    - "Skipping step 2 (after also skipping step 1) redirects to the dashboard with the notice 'You can complete setup any time from Settings.'"
    - "After skipping both steps, onboarding_complete? is true so DashboardController#check_onboarding returns early without issuing a second redirect"
  artifacts:
    - path: "app/controllers/onboarding_controller.rb"
      provides: "Fixed skip action for step 2"
      contains: "onboarding_personal_best_done: true, onboarding_medication_done: true"
    - path: "test/controllers/onboarding_controller_test.rb"
      provides: "Test covering skip-both-steps flash notice path"
      contains: "flash[:notice]"
  key_links:
    - from: "OnboardingController#skip (step 2)"
      to: "DashboardController#check_onboarding"
      via: "onboarding_complete? returning true"
      pattern: "onboarding_personal_best_done.*true.*onboarding_medication_done.*true"
---

<objective>
Close the UAT gap where skipping step 2 (after having skipped step 1) discards the flash notice because DashboardController#check_onboarding fires a second redirect.

Purpose: Skipping step 2 must conclusively mark onboarding as complete so the dashboard guard is a no-op and the flash notice survives.
Output: One-line controller fix + two targeted tests confirming the flash is present and both flags are true.
</objective>

<execution_context>
@~/.claude/ariadna/workflows/execute-plan.md
@~/.claude/ariadna/templates/summary.md
</execution_context>

<context>
@.ariadna_planning/PROJECT.md
@.ariadna_planning/ROADMAP.md
@.ariadna_planning/STATE.md
@.ariadna_planning/phases/17-onboarding-flow/17-UAT.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Fix OnboardingController#skip step 2 to set both onboarding flags</name>
  <files>app/controllers/onboarding_controller.rb</files>
  <action>
In the `skip` action, locate the `when 2` branch. Change the single-attribute update to set both flags atomically:

Before:
```ruby
when 2
  Current.user.update!(onboarding_medication_done: true)
```

After:
```ruby
when 2
  Current.user.update!(onboarding_personal_best_done: true, onboarding_medication_done: true)
```

This ensures `onboarding_complete?` (which requires both flags true) is definitively true after skipping step 2, regardless of whether step 1 was completed or skipped. The JSON branch in `when 2` may also include `onboarding_personal_best_done: true` in its response body for consistency, but is not the primary concern.

Do NOT change any other branch (when 1, submit_1, submit_2). Do NOT change any before_action or guard logic.
  </action>
  <verify>
Run `bin/rails test test/controllers/onboarding_controller_test.rb` — all tests must pass.
  </verify>
  <done>
The `when 2` branch calls `Current.user.update!(onboarding_personal_best_done: true, onboarding_medication_done: true)`. Both flags are true after the call. `onboarding_complete?` returns true. All existing controller tests still pass.
  </done>
</task>

<task type="auto">
  <name>Task 2: Add controller tests for skip-step-2 flash notice and skip-both-steps path</name>
  <files>test/controllers/onboarding_controller_test.rb</files>
  <action>
The existing test "PATCH skip step 2 sets medication_done flag and redirects to dashboard" only asserts the redirect and the medication_done flag. It does not assert the flash notice, and the setup user (new_user) still has `onboarding_personal_best_done: false`, which means the bug path is not covered.

Replace the existing skip-step-2 test with two tests that together cover both the happy path and the bug scenario:

1. **Test: skip step 2 after completing step 1 — flash notice present**
   Setup: Set `@new_user.update!(onboarding_personal_best_done: true)` before the request (user completed step 1). Send `PATCH onboarding_skip_path(2)`. Assert redirect to `dashboard_path`. Follow the redirect with `follow_redirect!`. Assert `flash[:notice]` equals `"You can complete setup any time from Settings."`. Assert `@new_user.reload.onboarding_medication_done?` is true.

2. **Test: skip both steps — both flags true and flash notice survives to dashboard**
   Setup: User has both flags false (default new_user in setup). Send `PATCH onboarding_skip_path(2)`. Assert redirect to `dashboard_path`. Assert `@new_user.reload.onboarding_personal_best_done?` is true. Assert `@new_user.reload.onboarding_medication_done?` is true. Follow the redirect. Assert `flash[:notice]` equals `"You can complete setup any time from Settings."`.

Place both tests in the `# -- Skip step 2 --` section, directly replacing the single existing skip-step-2 test.

Use `follow_redirect!` to assert flash after redirect — the flash is unconsumed until the next request, so calling `follow_redirect!` then checking `flash[:notice]` on the response is the correct pattern for `ActionDispatch::IntegrationTest`.

Note: `flash[:notice]` is accessible on the response after `follow_redirect!` via `flash` (the integration test helper exposes this). Alternatively assert `assert_match "You can complete setup any time from Settings.", response.body` after the follow if flash is not directly accessible — but prefer `assert_equal "...", flash[:notice]` first.
  </action>
  <verify>
Run `bin/rails test test/controllers/onboarding_controller_test.rb` — all 14 tests (13 existing minus 1 replaced + 2 new = 14 total) must pass. No failures, no errors.

Run `bin/rails test` to confirm no regressions in the full suite.
  </verify>
  <done>
Two new tests exist covering: (a) skip-step-2 after step-1-done with flash present, (b) skip-both-steps with both flags true and flash present after redirect. All 14 controller tests pass. Full suite passes with no regressions.
  </done>
</task>

</tasks>

<verification>
bin/rails test test/controllers/onboarding_controller_test.rb
bin/rails test
</verification>

<success_criteria>
- `OnboardingController#skip` when step == 2 updates both `onboarding_personal_best_done: true` and `onboarding_medication_done: true`
- `onboarding_complete?` returns true after skipping step 2, regardless of step 1 state
- Flash notice "You can complete setup any time from Settings." is not discarded by a second dashboard redirect
- Controller test suite has at least 14 tests, all passing
- Full test suite passes with no regressions (baseline: 391 tests)
</success_criteria>

<output>
After completion, create `.ariadna_planning/phases/17-onboarding-flow/17-gap-01-SUMMARY.md` summarising:
- The one-line change made in onboarding_controller.rb
- The two tests added and what they assert
- Final test count
</output>
