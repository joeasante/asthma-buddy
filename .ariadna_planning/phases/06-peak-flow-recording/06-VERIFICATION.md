---
phase: 06-peak-flow-recording
verified: 2026-03-07T17:42:41Z
status: passed
score: 17/17 must-haves verified | security: 0 critical, 0 high | performance: 0 high
re_verification:
  previous_status: passed
  previous_score: 14/14
  previous_verified: 2026-03-07T16:39:23Z
  gaps_closed:
    - "Blank value on peak flow form now blocked at browser via HTML5 required attribute"
    - "Flash messages replace rather than accumulate — turbo_stream.replace 'flash-messages' targeting stable id div"
    - "Zone name in flash displays in zone colour via html_safe span with zone-label CSS classes"
  gaps_remaining: []
  regressions: []
---

# Phase 6: Peak Flow Recording Verification Report

**Phase Goal:** Users can record peak flow readings with zone colour feedback and flash messages that replace correctly. Personal best management works from settings.
**Verified:** 2026-03-07T17:42:41Z
**Status:** PASSED
**Re-verification:** Yes — after plan-05 UAT gap closure (plan-05 completed 2026-03-07T17:39:49Z, after initial verification at 16:39:23Z)

---

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | A PeakFlowReading can be saved with a numeric value and timestamp for a user | VERIFIED | `app/models/peak_flow_reading.rb` validates value (integer 1-900) and recorded_at; schema has both columns |
| 2  | A PersonalBestRecord can be saved with a numeric value and timestamp for a user | VERIFIED | `app/models/personal_best_record.rb` validates value (100-900) and recorded_at; schema has both columns |
| 3  | PeakFlowReading#zone_for_personal_best returns :green, :yellow, :red, or nil when no personal best exists | VERIFIED | `compute_zone` method present; returns nil when no pb, :green >= 80%, :yellow 50-79%, :red < 50% |
| 4  | Zone thresholds: green >= 80% of personal best, yellow 50-79%, red < 50% | VERIFIED | Exact thresholds in `compute_zone`; tested in model tests — 152 tests, 0 failures |
| 5  | PersonalBestRecord.current_for(user) returns the most recent record | VERIFIED | `user.personal_best_records.chronological.first` — tested in model tests |
| 6  | A logged-in user can visit /peak-flow-readings/new and see the entry form | VERIFIED | Route `resources :peak_flow_readings, path: "peak-flow-readings", only: %i[new create]`; controller and view substantive |
| 7  | The form has a large numeric input for reading value with L/min unit label | VERIFIED | `_form.html.erb` number_field with `class: "peak-flow-value-input"` and `aria-hidden` L/min span; CSS sets font-size: 2rem |
| 8  | Submitting a blank value field is blocked at the browser without a server round-trip | VERIFIED | `required: true` on `number_field :value` at line 29 of `_form.html.erb` — HTML5 native constraint |
| 9  | A contextual banner appears when user has no personal best set, linking to /settings | VERIFIED | `.peak-flow-banner` div conditionally rendered based on `has_personal_best`; links to `settings_path` |
| 10 | Submitting a valid reading saves it and shows a zone-aware flash message | VERIFIED | `zone_flash_message` in controller; `create.turbo_stream.erb` replaces `flash-messages` div with the message |
| 11 | Flash shows zone name in zone colour when personal best exists | VERIFIED | `zone_flash_message` returns `html_safe` string containing `<span class="zone-label zone-label--#{zone}">` with zone name and percentage; `raw @flash_message` renders it unescaped |
| 12 | Flash shows 'set your personal best to see your zone' when no personal best | VERIFIED | Nil-zone branch returns plain text string (no html_safe needed); tested in controller tests |
| 13 | Flash messages replace rather than accumulate on successive submissions | VERIFIED | `turbo_stream.replace "flash-messages"` in `create.turbo_stream.erb` replaces the stable `<div id="flash-messages">` in layout — no prepend |
| 14 | After a successful submission the form resets (value clears, datetime resets to current time) | VERIFIED | `turbo_stream.replace "peak_flow_reading_form"` wraps re-rendered partial in `turbo_frame_tag "peak_flow_reading_form"` — frame persists in DOM, fresh `recorded_at: Time.current.change(sec: 0)` |
| 15 | A logged-in user can visit /settings and set/update personal best (100-900 L/min) | VERIFIED | `SettingsController#show` and `#update_personal_best`; validation 100-900 in model; scoped via `Current.user.personal_best_records.new(...)` |
| 16 | The current personal best value is displayed on the settings page | VERIFIED | `show.html.erb` renders `@current_personal_best.value` in `<strong>` or "No personal best set yet." |
| 17 | A user cannot create readings or personal best records for another user | VERIFIED | Both controllers scope creates to `Current.user.peak_flow_readings.new(...)` and `Current.user.personal_best_records.new(...)` — no unscoped finds |

**Score:** 17/17 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `app/models/peak_flow_reading.rb` | PeakFlowReading with validations, zone enum, compute_zone, zone_percentage | VERIFIED | 43 lines; belongs_to :user, enum :zone, validates value/recorded_at, before_save :assign_zone, zone_percentage method |
| `app/models/personal_best_record.rb` | PersonalBestRecord with validations and current_for scope | VERIFIED | 18 lines; belongs_to :user, validates value (100-900), current_for class method |
| `app/models/user.rb` | User with has_many associations | VERIFIED | has_many :peak_flow_readings and :personal_best_records with dependent: :destroy |
| `app/controllers/peak_flow_readings_controller.rb` | Controller with new, create, zone_flash_message — returns html_safe coloured span | VERIFIED | 68 lines; zone_flash_message returns html_safe string with zone-label span; scoped to Current.user |
| `app/controllers/settings_controller.rb` | SettingsController with show and update_personal_best | VERIFIED | 49 lines; show loads @current_personal_best and blank @personal_best_record; update_personal_best scoped to Current.user |
| `app/views/peak_flow_readings/_form.html.erb` | Form partial with required value field, banner, datetime | VERIFIED | 43 lines; number_field with required: true, min: 1, max: 900; banner conditional on has_personal_best |
| `app/views/peak_flow_readings/create.turbo_stream.erb` | Turbo Stream: replace form with frame wrapper, replace flash-messages with raw flash | VERIFIED | 17 lines; turbo_frame_tag wrapper on form replace; turbo_stream.replace "flash-messages" with raw @flash_message |
| `app/views/layouts/application.html.erb` | Layout with stable id="flash-messages" div always rendered | VERIFIED | Lines 47-54: unconditional `<div id="flash-messages">` containing conditional flash paragraphs |
| `app/views/settings/show.html.erb` | Settings page displaying current PB and form | VERIFIED | Displays @current_personal_best.value or "No personal best set yet."; renders _personal_best_form partial |
| `app/views/settings/_personal_best_form.html.erb` | Personal best form partial with url: settings_personal_best_path | VERIFIED | form_with url: settings_personal_best_path; number_field :value min:100, max:900; L/min label |
| `app/assets/stylesheets/peak_flow.css` | Zone colour CSS classes using --severity-* custom properties | VERIFIED | Lines 52-58: .zone-label (font-weight:600), .zone-label--green/yellow/red using var(--severity-mild/moderate/severe) |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `create.turbo_stream.erb` | `_form.html.erb` | `turbo_stream.replace "peak_flow_reading_form"` with `turbo_frame_tag` wrapper | WIRED | Line 2-10: replace wraps re-rendered partial in matching turbo_frame_tag — frame persists across submissions |
| `create.turbo_stream.erb` | `application.html.erb` `id="flash-messages"` | `turbo_stream.replace "flash-messages"` | WIRED | Line 13: replaces stable div in layout; layout always renders `<div id="flash-messages">` at line 47 |
| `peak_flow_readings_controller.rb` | `create.turbo_stream.erb` | `@flash_message` set as html_safe; `raw @flash_message` in template | WIRED | Controller line 53: `.html_safe` on zone flash; template line 15: `raw @flash_message` renders unescaped |
| `PeakFlowReading` | `User` | `belongs_to :user` | WIRED | Model line 3 |
| `PersonalBestRecord` | `User` | `belongs_to :user` | WIRED | Model line 3 |
| `User` | `PeakFlowReading`, `PersonalBestRecord` | `has_many` with `dependent: :destroy` | WIRED | Both associations in user.rb |
| `config/routes.rb` | `PeakFlowReadingsController` | `resources :peak_flow_readings, path: "peak-flow-readings", only: %i[new create]` | WIRED | Route line 10; controller has both action methods |
| `config/routes.rb` | `SettingsController` | `get "settings"` and `post "settings/personal_best"` | WIRED | Routes lines 12-13; controller has show and update_personal_best |
| `_form.html.erb` | `PeakFlowReadingsController#create` | `form_with model: peak_flow_reading` | WIRED | form_with renders to peak_flow_readings_path (POST) |
| `SettingsController` | `PersonalBestRecord` | `Current.user.personal_best_records.new(personal_best_params)` | WIRED | Controller line 23 |
| `PeakFlowReadingsController` | `PersonalBestRecord` | `PersonalBestRecord.current_for(Current.user)` | WIRED | Called in new (line 10) and create (lines 18, 25) |

---

### Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| PEAK-01: Logged-in user can record a peak flow reading via the entry form | SATISFIED | Route, controller, form, Turbo Stream response all present and tested; blank-submit blocked via required attribute |
| PEAK-02: Logged-in user can set their personal best in settings | SATISFIED | Settings route, controller, form partial, model validation all present and tested |
| PEAK-03: Zone is computed and appears in the flash message after saving | SATISFIED | zone_flash_message in controller returns coloured html_safe span; create.turbo_stream.erb renders it; flash replaces rather than accumulates |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `app/views/peak_flow_readings/_form.html.erb` | 30 | `placeholder:` HTML attribute | Info | Form field placeholder text — not a code anti-pattern |
| `app/views/settings/_personal_best_form.html.erb` | — | `placeholder:` HTML attribute | Info | Form field placeholder text — not a code anti-pattern |

No blockers or warnings found.

---

### Security Findings

Brakeman scan: **0 security warnings** across 10 controllers, 7 models, 24 templates.
Bundler-audit: **No vulnerabilities found** (1063 advisories checked, db updated 2026-03-06).

Scoped resource access confirmed: both controllers use `Current.user.peak_flow_readings` and `Current.user.personal_best_records` — no unscoped finds. Strong params enforced: `permit(:value, :recorded_at)` and `permit(:value)` respectively.

Note on `html_safe` usage: `zone_flash_message` constructs the HTML span directly in the controller (no user input interpolated — only `reading.zone` from enum and `reading.zone_percentage` computed from integers). This is the correct Rails pattern for controller-generated HTML fragments; `raw()` in the template is intentional and safe here.

**Security:** 0 findings (0 critical, 0 high, 0 medium)

---

### Performance Findings

New and create actions only — no index/list views. Single-record lookups for personal best (`PersonalBestRecord.current_for`) with no collection enumeration. Migrations include composite indexes on `[user_id, recorded_at]` for both tables — appropriate for timeline queries in future phases.

**Performance:** 0 findings (0 high, 0 medium, 0 low)

---

### Human Verification Required

The following behaviors cannot be fully verified without running a browser:

#### 1. Zone Flash Colour Rendering

**Test:** Sign in, ensure a personal best of 520 L/min is set, visit `/peak-flow-readings/new`, submit a value of 450. Observe the flash message.
**Expected:** Flash message appears inline (no full page reload) reading "Reading saved — Green Zone (87% of personal best)." with "Green Zone (87% of personal best)" rendered in green text (matching the colour of mild/green symptoms).
**Why human:** CSS `color: var(--severity-mild)` rendering and the visual colour appearance require a browser session.

#### 2. Flash Replace (Not Accumulate) Behaviour

**Test:** Submit two successive valid readings on `/peak-flow-readings/new` without page reload.
**Expected:** After each submission only one flash message is visible — the new one replacing the previous one.
**Why human:** Turbo Stream DOM mutation across successive submissions requires a live browser session to observe the replace-not-accumulate behaviour.

#### 3. Blank Submit Blocked Natively

**Test:** Visit `/peak-flow-readings/new`, leave the value field empty, click "Log reading".
**Expected:** Browser shows a native "Please fill in this field" tooltip (or equivalent) — no network request is made, no Rails error appears.
**Why human:** HTML5 constraint validation tooltip appearance requires a browser session.

#### 4. Form Reset After Submission

**Test:** Submit a valid reading, then observe the value field and datetime field.
**Expected:** Value field is empty; datetime resets to approximately the current time.
**Why human:** Turbo Stream DOM replacement and datetime field reset require visual confirmation in a browser.

---

### Gaps Summary

No gaps found. All 17 observable truths verified against the actual codebase.

**Plan-05 gap closure confirmed:** The three UAT gaps identified after the initial phase verification have been fully addressed:
1. `required: true` on the value `number_field` blocks blank submits at the browser.
2. `<div id="flash-messages">` always rendered in layout; `turbo_stream.replace "flash-messages"` in the Turbo Stream response ensures each flash replaces the previous one.
3. `zone_flash_message` returns an `html_safe` string wrapping the zone name and percentage in `<span class="zone-label zone-label--{zone}">`, rendered via `raw @flash_message` in the template; `.zone-label--green/yellow/red` CSS classes use `var(--severity-mild/moderate/severe)` custom properties.

Full test suite: **152 runs, 430 assertions, 0 failures, 0 errors, 0 skips.**
Brakeman: **0 security warnings.** Bundler-audit: **0 vulnerabilities.**

---

_Verified: 2026-03-07T17:42:41Z_
_Verifier: Claude (ariadna-verifier)_
