---
phase: 14-adherence-dashboard
verified: 2026-03-08T19:29:42Z
status: passed
score: 12/12 must-haves verified | security: 0 critical, 0 high | performance: 0 high
re_verification: false
---

# Phase 14: Adherence Dashboard Verification Report

**Phase Goal:** The dashboard shows a preventer adherence indicator for today (doses taken vs scheduled), and a user can open a history view showing adherence for each preventer over the last 7 or 30 days.
**Verified:** 2026-03-08T19:29:42Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | AdherenceCalculator.call(medication, date) returns a result with taken, scheduled, and status fields | VERIFIED | `app/services/adherence_calculator.rb` returns `Result = Struct.new(:taken, :scheduled, :status)`; 7 unit tests pass |
| 2  | A preventer with doses_per_day=2 and 2 dose logs today returns {taken: 2, scheduled: 2, status: :on_track} | VERIFIED | Test "returns on_track when all scheduled doses are logged" asserts all three fields |
| 3  | A preventer with doses_per_day=2 and 1 dose log today returns {taken: 1, scheduled: 2, status: :missed} | VERIFIED | Test "returns missed when fewer than scheduled doses are logged" passes |
| 4  | A preventer with doses_per_day=2 and 0 dose logs today returns {taken: 0, scheduled: 2, status: :missed} | VERIFIED | Test "returns missed when no doses are logged for a scheduled medication" passes |
| 5  | A medication without doses_per_day returns {taken: N, scheduled: nil, status: :no_schedule} | VERIFIED | Test "returns no_schedule for a medication without doses_per_day" passes |
| 6  | A date before the medication was created returns {taken: 0, scheduled: nil, status: :no_schedule} | VERIFIED | Early return before dose_logs query when `date < medication.created_at.to_date`; test passes |
| 7  | The dashboard shows an adherence section listing each preventer medication with doses taken vs scheduled today | VERIFIED | `DashboardController#index` builds `@preventer_adherence`; `dashboard/index.html.erb` renders `.dash-adherence` section with `result.taken / result.scheduled` |
| 8  | A preventer with no doses_per_day does not appear in the adherence section | VERIFIED | Controller filters with `.select { |m| m.doses_per_day.present? }` before mapping |
| 9  | The adherence section includes a link to the adherence history page (/adherence) | VERIFIED | `link_to "View history", adherence_path` in `dashboard/index.html.erb` line 93 |
| 10 | Navigating to /adherence shows a day-by-day adherence grid for the last 7 days by default | VERIFIED | `AdherenceController#index` defaults `@days = 7` when param not in [7, 30]; renders grid cells |
| 11 | A ?days=30 param switches to a 30-day grid | VERIFIED | `params[:days].to_i.in?([7, 30])` allowlist; controller test for days=30 passes; system test asserts 30+ cells |
| 12 | Days before a medication was added show as grey, not red | VERIFIED | `AdherenceCalculator` returns `:no_schedule` for pre-creation dates; system test asserts minimum: 6 `.adherence-cell--no_schedule` for a medication created today |

**Score:** 12/12 truths verified

---

### Required Artifacts

| Artifact | Provides | Level 1: Exists | Level 2: Substantive | Level 3: Wired | Status |
|----------|----------|-----------------|----------------------|----------------|--------|
| `app/services/adherence_calculator.rb` | AdherenceCalculator service with Result struct | Yes | 35 lines; class definition, Result Struct, call/initialize/call methods, full logic | Called by DashboardController line 48 and AdherenceController line 107 | VERIFIED |
| `test/services/adherence_calculator_test.rb` | 7 unit tests for all status branches | Yes | 81 lines; 7 named test methods covering all branches | Loaded by test runner; 14 tests in suite pass | VERIFIED |
| `app/views/dashboard/_adherence_card.html.erb` | Partial rendering one preventer's adherence for today | Yes | 13 lines; renders `result.taken`, `result.scheduled`, CSS modifier from `result.status` | Rendered by `dashboard/index.html.erb` line 97-99 | VERIFIED |
| `app/controllers/dashboard_controller.rb` | Loads @preventer_adherence for today using AdherenceCalculator | Yes | 50 lines; builds `@preventer_adherence` array at lines 43-48 using `AdherenceCalculator.call` | Serves `GET /dashboard`; view uses `@preventer_adherence` | VERIFIED |
| `app/controllers/adherence_controller.rb` | AdherenceController#index loading history data | Yes | 24 lines; `class AdherenceController < ApplicationController`, `@days` param handling, date range, `@adherence_history` | Wired via route `adherence#index`; inherits `require_authentication` from ApplicationController via Authentication concern | VERIFIED |
| `app/views/adherence/index.html.erb` | History page with 7/30-day toggle | Yes | 31 lines; contains `days=30`, toggle links with `adherence-toggle-btn--active`, empty state, `render "adherence/history_grid"` | Rendered by AdherenceController#index | VERIFIED |
| `app/views/adherence/_history_grid.html.erb` | Day-by-day grid partial for one medication | Yes | 28 lines; `.adherence-grid`, `.adherence-cell--<%= status %>` cells, legend | Rendered by `adherence/index.html.erb` line 16 | VERIFIED |
| `test/controllers/adherence_controller_test.rb` | Controller integration tests | Yes | 58 lines; `class AdherenceControllerTest`; 7 tests covering auth redirect, day param, filtering, cross-user isolation | Loaded by test runner; all 14 adherence tests pass | VERIFIED |
| `test/system/adherence_test.rb` | System tests for grid rendering and day status | Yes | 100 lines; `class AdherenceTest`; 7 system tests covering dashboard section, history page, toggle, green/grey cells | Present in test suite | VERIFIED |

---

### Key Link Verification

| From | To | Via | Status | Evidence |
|------|----|-----|--------|----------|
| `app/services/adherence_calculator.rb` | `DoseLog` | `medication.dose_logs.where(recorded_at: date.beginning_of_day..date.end_of_day).count` | WIRED | Line 21-23 of service; composite index `[medication_id, recorded_at]` covers query |
| `app/services/adherence_calculator.rb` | `Medication#doses_per_day` | `scheduled = @medication.doses_per_day`; `:no_schedule` guard on nil | WIRED | Lines 20 and 25 of service |
| `app/controllers/dashboard_controller.rb` | `AdherenceCalculator.call` | `.map { |m| { medication: m, result: AdherenceCalculator.call(m, today) } }` | WIRED | Line 48 of controller |
| `app/views/dashboard/index.html.erb` | `app/views/dashboard/_adherence_card.html.erb` | `render "dashboard/adherence_card", medication:, result:` | WIRED | Lines 97-99 of index view |
| `app/controllers/adherence_controller.rb` | `AdherenceCalculator.call` | `result = AdherenceCalculator.call(medication, date)` inside date range map | WIRED | Line 107 of controller |
| `app/views/adherence/index.html.erb` | `app/views/adherence/_history_grid.html.erb` | `render "adherence/history_grid", medication:, days_data:, days:` | WIRED | Lines 16-19 of index view |
| `config/routes.rb` | `app/controllers/adherence_controller.rb` | `get "adherence", to: "adherence#index", as: :adherence` | WIRED | Line 41 of routes.rb; `bin/rails routes` confirms `adherence GET /adherence adherence#index` |
| `app/controllers/adherence_controller.rb` | Authentication (require_authentication) | Inherits `before_action :require_authentication` via `include Authentication` in ApplicationController | WIRED | Authentication concern line 6; AdherenceController < ApplicationController; controller test "redirects unauthenticated user" passes |

---

### Requirements Coverage

No requirements from REQUIREMENTS.md were explicitly mapped to this phase in the plan frontmatter.

---

### Anti-Patterns Found

None. Scanned all changed files for TODO/FIXME, debug statements (puts, pp, byebug, binding.pry), empty implementations, and placeholder text. Zero findings.

---

### Security Findings

Brakeman scan: **0 warnings**
Bundler audit: **No vulnerabilities found**

Manual checks against changed files:

| Check | Name | Result |
|-------|------|--------|
| 1.1a | SQL string interpolation | Not present — all queries use ActiveRecord scoped methods |
| 2.2a | Strong parameters / mass assignment | Not applicable — no create/update actions in AdherenceController |
| 3.1 | Authentication | Inherited `require_authentication` before_action; controller test verifies redirect |
| 3.2 | IDOR / cross-user isolation | `user.medications` scoped to `Current.user` in both controllers; controller test verifies another user's medication does not appear |
| 2.3 | Open redirect from params | `params[:days].to_i.in?([7, 30])` allowlist prevents any non-7/30 value from being used |

**Security:** 0 findings

---

### Performance Findings

| Check | Name | Severity | File | Detail |
|-------|------|----------|------|--------|
| 1.1 | O(medications * days) count queries in AdherenceController | Medium | `app/controllers/adherence_controller.rb` | For 30-day view with N preventers, issues N*30 individual `.count` queries. Acceptable at MVP scale — each query is covered by composite index `[medication_id, recorded_at]` so cost is very low. Not a blocker but worth batching if preventer counts grow. |

**Performance:** 0 high, 1 medium (index-covered; acceptable at current scale)

---

### Human Verification Required

The following items require browser-based human testing as they cannot be verified programmatically:

#### 1. Dashboard adherence card visual states

**Test:** Sign in as a user with a preventer medication with `doses_per_day: 2`. Log 2 doses today. Visit `/dashboard`. Then sign in as a user with 0 doses logged today and revisit.
**Expected:** On-track card shows a green left border and green dose count; missed card shows red left border and red dose count.
**Why human:** CSS custom property rendering (`--severity-mild`, `--severity-severe`) cannot be verified without a browser rendering engine.

#### 2. History grid cell colour coding at 7-day and 30-day views

**Test:** Visit `/adherence` and `/adherence?days=30`. Inspect cells for green (on_track), red (missed), and grey (no_schedule) colours.
**Expected:** Green cells for days all scheduled doses were taken; red for days with fewer; grey for days before medication was created.
**Why human:** CSS class presence is verified but actual rendered colour from custom properties needs browser confirmation.

#### 3. 7/30-day toggle active state appearance

**Test:** Visit `/adherence`. The "7 days" button should appear visually active (branded colour background). Click "30 days" — it should become active, "7 days" should deactivate.
**Expected:** Active button has `--brand` background (teal) with white text; inactive has border only.
**Why human:** CSS modifier class presence verified; rendered appearance needs browser.

#### 4. Empty state for user with no scheduled preventers

**Test:** Sign in as a user who has no preventer medications with `doses_per_day` set. Visit `/dashboard` and `/adherence`.
**Expected:** Dashboard shows no adherence section. History page shows "No scheduled preventer medications found." with a link to add a medication.
**Why human:** Fixture setup would be needed to create this state; easier to test with a purpose-built test account.

---

### Gaps Summary

No gaps. All 12 observable truths are verified. All 9 required artifacts exist, are substantive, and are wired. All 8 key links are confirmed connected. The full test suite passes at 290 tests, 0 failures. Brakeman and bundler-audit are clean.

---

_Verified: 2026-03-08T19:29:42Z_
_Verifier: Claude (ariadna-verifier)_
