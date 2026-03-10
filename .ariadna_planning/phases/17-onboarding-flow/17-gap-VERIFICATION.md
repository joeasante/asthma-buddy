---
phase: 17-onboarding-flow
plan: gap-01
verified: 2026-03-10T18:15:51Z
status: passed
score: 2/2 must-haves verified | security: 0 critical, 0 high | performance: 0 high
---

# Phase 17 Gap-01: Onboarding Skip Flash Notice — Verification Report

**Phase Goal:** The flash notice "You can complete setup any time from Settings." must appear on the dashboard after skipping both onboarding steps. Root cause was: skip-step-2 only set `onboarding_medication_done`, leaving `onboarding_personal_best_done` false, causing `check_onboarding` to redirect again and discard the flash. Fix: set both flags when skipping step 2.
**Verified:** 2026-03-10T18:15:51Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth                                                                                                                                       | Status     | Evidence                                                                                                                                                                               |
|----|---------------------------------------------------------------------------------------------------------------------------------------------|------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1  | Skipping step 2 (after also skipping step 1) redirects to the dashboard with the notice "You can complete setup any time from Settings."   | VERIFIED   | `when 2` branch in `OnboardingController#skip` (line 90): `Current.user.update!(onboarding_personal_best_done: true, onboarding_medication_done: true)` followed by redirect with notice |
| 2  | After skipping both steps, `onboarding_complete?` is true so `DashboardController#check_onboarding` returns early without a second redirect | VERIFIED   | `User#onboarding_complete?` (user.rb line 35-37) ANDs both flags; `DashboardController#check_onboarding` (dashboard_controller.rb line 104): `return if Current.user.onboarding_complete?` |

**Score:** 2/2 truths verified

---

### Required Artifacts

| Artifact                                         | Expected                                        | Status    | Details                                                                                                                                                                                           |
|--------------------------------------------------|-------------------------------------------------|-----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `app/controllers/onboarding_controller.rb`       | Fixed skip action for step 2                    | VERIFIED  | Line 90: `Current.user.update!(onboarding_personal_best_done: true, onboarding_medication_done: true)` — both flags set atomically in `when 2` branch                                             |
| `test/controllers/onboarding_controller_test.rb` | Tests covering skip-both-steps flash notice path | VERIFIED  | Two tests present (lines 98-114): "skip step 2 after completing step 1 — flash notice present" and "skip both steps — both flags true and flash notice survives to dashboard", both assert `flash[:notice]` |

---

### Key Link Verification

| From                             | To                                    | Via                                       | Status  | Details                                                                                                                                                                      |
|----------------------------------|---------------------------------------|-------------------------------------------|---------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `OnboardingController#skip` (step 2) | `DashboardController#check_onboarding` | `onboarding_complete?` returning true     | WIRED   | `when 2` sets both flags (line 90), `User#onboarding_complete?` ANDs both (user.rb line 36), `check_onboarding` returns early on true (dashboard_controller.rb line 104) |

**Wiring chain confirmed:** skip-step-2 sets both flags → `onboarding_complete?` returns true → `check_onboarding` is a no-op → flash survives to the dashboard response.

---

### Requirements Coverage

No requirements from REQUIREMENTS.md mapped to this gap phase. N/A.

---

### Anti-Patterns Found

No anti-patterns detected in `app/controllers/onboarding_controller.rb` or `test/controllers/onboarding_controller_test.rb`.

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| —    | —    | —       | —        | —      |

---

### Security Findings

No security issues found. Controller uses strong parameters (`medication_params`), no string interpolation in SQL, no unscoped finds using user-supplied params.

**Security:** 0 findings (0 critical, 0 high, 0 medium)

---

### Performance Findings

No performance issues found. Controller update is a single-row write; no N+1 risk introduced.

**Performance:** 0 findings (0 high, 0 medium, 0 low)

---

### Test Execution Results

`bin/rails test test/controllers/onboarding_controller_test.rb` output:

```
Running 14 tests in a single process
14 runs, 46 assertions, 0 failures, 0 errors, 0 skips
```

All 14 tests pass. The two new tests specifically covering the flash-after-skip-both-steps path are present and passing.

---

### Human Verification Required

One item cannot be verified programmatically:

#### 1. Flash message visual rendering on dashboard

**Test:** Sign in as a new user (both flags false). Navigate to `/onboarding/step/1`, click "Skip". Navigate to `/onboarding/step/2`, click "Skip". Observe the dashboard page that loads.
**Expected:** A flash notice banner reading "You can complete setup any time from Settings." is visible on the dashboard.
**Why human:** Visual rendering, CSS styling, and Turbo frame/stream behaviour cannot be asserted via integration tests.

---

### Gaps Summary

No gaps. Both must-have truths are fully verified at all three levels (exists, substantive, wired). The fix is a single-line change in the `when 2` branch of `OnboardingController#skip` that atomically sets both `onboarding_personal_best_done: true` and `onboarding_medication_done: true`, ensuring `onboarding_complete?` returns `true` and `DashboardController#check_onboarding` is a no-op, allowing the flash notice to survive to the dashboard response.

---

_Verified: 2026-03-10T18:15:51Z_
_Verifier: Claude (ariadna-verifier)_
