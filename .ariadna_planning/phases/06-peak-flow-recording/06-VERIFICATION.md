---
phase: 06-peak-flow-recording
verified: 2026-03-07T16:39:23Z
status: passed
score: 14/14 must-haves verified | security: 0 critical, 0 high | performance: 0 high
---

# Phase 6: Peak Flow Recording Verification Report

**Phase Goal:** Users can record peak flow readings and see their zone (green/yellow/red) relative to their personal best.
**Verified:** 2026-03-07T16:39:23Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | A PeakFlowReading can be saved with a numeric value and timestamp for a user | VERIFIED | `app/models/peak_flow_reading.rb` validates value (integer > 0) and recorded_at; schema has both columns |
| 2  | A PersonalBestRecord can be saved with a numeric value and timestamp for a user | VERIFIED | `app/models/personal_best_record.rb` validates value (100-900) and recorded_at; schema has both columns |
| 3  | PeakFlowReading#zone_for_personal_best returns :green, :yellow, :red, or nil when no personal best exists | VERIFIED | `compute_zone` method present and correct; model tests cover all 4 paths and pass |
| 4  | Zone thresholds: green >= 80% of personal best, yellow 50-79%, red < 50% | VERIFIED | Exact thresholds implemented in `compute_zone`; model tests verify green (420/520 = 80.7%), yellow (280/520 = 53.8%), red (200/520 = 38.4%) |
| 5  | PersonalBestRecord.current_for(user) returns the most recent record | VERIFIED | `chronological.first` on user's personal_best_records; tested in model tests |
| 6  | A logged-in user can visit /peak_flow_readings/new and see the entry form | VERIFIED | `resources :peak_flow_readings, only: %i[new create]` in routes; controller and view exist and substantive |
| 7  | The form has a large numeric input for reading value with L/min unit label | VERIFIED | `_form.html.erb` has `peak-flow-value-input` class, `aria-hidden` L/min span, `peak_flow.css` sets font-size: 2rem |
| 8  | A contextual banner appears when user has no personal best set, linking to /settings | VERIFIED | Banner div `.peak-flow-banner` conditionally rendered; links to `settings_path`; controller sets `@has_personal_best` |
| 9  | Submitting a valid reading saves it and shows a zone-aware flash message | VERIFIED | `zone_flash_message` method in controller; Turbo Stream response in `create.turbo_stream.erb` prepends flash to `#main-content` |
| 10 | Flash shows zone name and percentage when personal best exists | VERIFIED | `"Reading saved — #{zone_label} Zone (#{percentage}% of personal best)."` in controller; controller test asserts "Green Zone" |
| 11 | Flash shows 'set your personal best to see your zone' when no personal best | VERIFIED | Nil-pb branch in `zone_flash_message`; controller test asserts "set your personal best" |
| 12 | A logged-in user can visit /settings and set/update personal best (100-900 L/min) | VERIFIED | `SettingsController#show` and `#update_personal_best`; validation 100-900 in model; settings controller tests pass |
| 13 | The current personal best value is displayed on the settings page | VERIFIED | `show.html.erb` renders `@current_personal_best.value` or "No personal best set yet."; controller test asserts `<strong>520</strong>` |
| 14 | A user cannot create readings or personal best records for another user | VERIFIED | Both controllers use `Current.user.peak_flow_readings.new(...)` and `Current.user.personal_best_records.new(...)` — scoped; isolation tests confirm |

**Score:** 14/14 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `app/models/peak_flow_reading.rb` | PeakFlowReading model with validations, zone enum, zone calculation | VERIFIED | 48 lines; belongs_to :user, enum :zone, validates value/recorded_at, compute_zone, before_save :assign_zone |
| `app/models/personal_best_record.rb` | PersonalBestRecord model with validations and current_for scope | VERIFIED | 18 lines; belongs_to :user, validates value (100-900), current_for class method |
| `app/models/user.rb` | User model with has_many associations | VERIFIED | has_many :peak_flow_readings, dependent: :destroy and has_many :personal_best_records, dependent: :destroy present |
| `db/migrate/20260307162243_create_peak_flow_readings.rb` | Migration creating peak_flow_readings table | VERIFIED | Creates table with value, recorded_at, zone (nullable), user_id, composite index on [user_id, recorded_at] |
| `db/migrate/20260307162318_create_personal_best_records.rb` | Migration creating personal_best_records table | VERIFIED | Creates table with value, recorded_at, user_id, composite index on [user_id, recorded_at] |
| `app/controllers/peak_flow_readings_controller.rb` | PeakFlowReadingsController with new and create actions | VERIFIED | 55 lines; new, create, zone_flash_message, peak_flow_reading_params all present |
| `app/controllers/settings_controller.rb` | SettingsController with show and update_personal_best actions | VERIFIED | 27 lines; show, update_personal_best, personal_best_params all present |
| `app/views/peak_flow_readings/new.html.erb` | Entry form page with turbo_frame_tag wrapping | VERIFIED | turbo_frame_tag "peak_flow_reading_form", renders _form partial |
| `app/views/peak_flow_readings/_form.html.erb` | Reusable form partial with banner, large numeric input, datetime | VERIFIED | Banner conditionally rendered, number_field :value, datetime_local_field :recorded_at |
| `app/views/peak_flow_readings/create.turbo_stream.erb` | Turbo Stream response: reset form + zone flash message | VERIFIED | turbo_stream.replace "peak_flow_reading_form" (form reset) + turbo_stream.prepend "main-content" (flash) |
| `app/views/settings/show.html.erb` | Settings page with personal best display and form | VERIFIED | Displays current PB value or "No personal best set yet.", renders _personal_best_form partial |
| `app/views/settings/_personal_best_form.html.erb` | Personal best form partial | VERIFIED | form_with url: settings_personal_best_path, number_field :value (min:100, max:900), L/min unit label |
| `app/assets/stylesheets/peak_flow.css` | Peak flow entry form styles | VERIFIED | .peak-flow-banner, .peak-flow-value-input (font-size:2rem), .peak-flow-unit, .peak-flow-value-input-row |
| `test/models/peak_flow_reading_test.rb` | Model unit tests for zone calculation | VERIFIED | 11 tests covering all zone paths, validations, chronological scope — all pass |
| `test/models/personal_best_record_test.rb` | Model unit tests for personal best lookup | VERIFIED | 8 tests covering validations, boundary values, current_for — all pass |
| `test/controllers/peak_flow_readings_controller_test.rb` | Controller integration tests | VERIFIED | 9 tests covering new, create, zone flash, no-PB flash, 422, isolation, unauthenticated — all pass |
| `test/controllers/settings_controller_test.rb` | Controller integration tests | VERIFIED | 8 tests covering show, update_personal_best, validation errors, unauthenticated, isolation — all pass |
| `test/system/peak_flow_recording_test.rb` | System test for full recording flow | VERIFIED | 5 Capybara scenarios covering full flow, banner, no-PB flash, blank error, settings→form |
| `test/fixtures/peak_flow_readings.yml` | Peak flow reading fixtures | VERIFIED | 4 fixtures: alice_green_reading, alice_yellow_reading, alice_no_pb_reading, bob_reading |
| `test/fixtures/personal_best_records.yml` | Personal best record fixtures | VERIFIED | 3 fixtures: alice_personal_best (500, 30d ago), alice_updated_personal_best (520, 7d ago), bob_personal_best |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| PeakFlowReading | User | belongs_to :user | WIRED | `belongs_to :user` on line 3 of model |
| PersonalBestRecord | User | belongs_to :user | WIRED | `belongs_to :user` on line 3 of model |
| User | PeakFlowReading, PersonalBestRecord | has_many with dependent: :destroy | WIRED | Both `has_many :peak_flow_readings, dependent: :destroy` and `has_many :personal_best_records, dependent: :destroy` in user.rb |
| config/routes.rb | PeakFlowReadingsController | resources :peak_flow_readings, only: %i[new create] | WIRED | Routes present; controller has both action methods |
| config/routes.rb | SettingsController | GET settings, POST settings/personal_best | WIRED | Both routes in routes.rb; controller has show and update_personal_best |
| _form.html.erb | PeakFlowReadingsController#create | form_with model: peak_flow_reading | WIRED | form_with model: peak_flow_reading renders to peak_flow_readings_path (POST) |
| settings/_personal_best_form.html.erb | SettingsController#update_personal_best | form_with url: settings_personal_best_path | WIRED | Explicit url: settings_personal_best_path, method: :post in partial |
| create.turbo_stream.erb | peak_flow_reading_form turbo_frame | turbo_stream.replace "peak_flow_reading_form" | WIRED | turbo_frame_tag "peak_flow_reading_form" in new.html.erb; turbo_stream.replace targets same id |
| create.turbo_stream.erb | #main-content | turbo_stream.prepend "main-content" | WIRED | Layout has `<main id="main-content">` at line 46 of application.html.erb |
| SettingsController | PersonalBestRecord | Current.user.personal_best_records.create | WIRED | `Current.user.personal_best_records.new(personal_best_params)` in update_personal_best |
| PeakFlowReadingsController | PersonalBestRecord | PersonalBestRecord.current_for | WIRED | Called in both new and create actions for `@has_personal_best` |

---

### Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| PEAK-01: Logged-in user can record a peak flow reading via the entry form | SATISFIED | Route, controller, form, Turbo Stream response all present and tested |
| PEAK-02: Logged-in user can set their personal best in settings | SATISFIED | Settings route, controller, form partial, model validation all present and tested |
| PEAK-03: Zone is computed and appears in the flash message after saving | SATISFIED | zone_flash_message in controller; create.turbo_stream.erb renders it; controller and system tests confirm |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `app/views/peak_flow_readings/_form.html.erb` | 29 | `placeholder:` HTML attribute | Info | Form field placeholder text — not a code anti-pattern |
| `app/views/settings/_personal_best_form.html.erb` | 21 | `placeholder:` HTML attribute | Info | Form field placeholder text — not a code anti-pattern |

No blockers or warnings found. Both "placeholder" matches are HTML input placeholder attributes, not code stubs.

---

### Security Findings

Brakeman scan: **0 security warnings** across 10 controllers, 7 models, 24 templates.
Bundler-audit: **No vulnerable gems found.**

Scoped resource access confirmed: both controllers use `Current.user.peak_flow_readings` and `Current.user.personal_best_records` — no unscoped finds. Strong params enforced via `permit(:value, :recorded_at)` and `permit(:value)` respectively.

**Security:** 0 findings (0 critical, 0 high, 0 medium)

---

### Performance Findings

The phase delivers new and create actions only (no list/index views). Single-record lookups for personal best (`PersonalBestRecord.current_for`) and no enumeration over collections. No N+1 risk in this scope.

Migrations include composite indexes on `[user_id, recorded_at]` for both tables — appropriate for future timeline queries.

**Performance:** 0 findings (0 high, 0 medium, 0 low)

---

### Human Verification Required

The following behaviors cannot be fully verified without running the browser:

#### 1. Zone Flash Appearance via Turbo Stream

**Test:** Sign in, visit `/peak_flow_readings/new` (with personal best set), submit a value of 450. Observe the flash message.
**Expected:** Flash appears inline (no full page reload) reading "Reading saved — Green Zone (86% of personal best)." and form resets to empty.
**Why human:** Turbo Stream DOM mutation and visual flash rendering require a browser session.

#### 2. Banner Conditional Visibility

**Test:** Visit `/peak_flow_readings/new` with no personal best set — confirm yellow banner appears with link to Settings. Then visit Settings, set a value, return to form — confirm banner is gone.
**Expected:** Banner appears when no personal best, disappears after setting one (without needing page reload if using Turbo, or after manual navigation).
**Why human:** Visual rendering of `.peak-flow-banner` requires browser confirmation.

#### 3. Large Numeric Input Appearance

**Test:** Visit `/peak_flow_readings/new` and observe the reading value input.
**Expected:** Input renders as a large (2rem) centred number field with "L/min" label to the right.
**Why human:** CSS rendering requires visual inspection.

---

### Gaps Summary

No gaps found. All 14 observable truths are verified against the actual codebase. All artifacts exist, are substantive (no stubs or placeholders), and are correctly wired. The full model+controller test suite (41 tests) passes with 0 failures, 0 errors. Brakeman and bundler-audit report clean results.

---

_Verified: 2026-03-07T16:39:23Z_
_Verifier: Claude (ariadna-verifier)_
