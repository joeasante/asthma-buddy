---
status: complete
phase: 06-peak-flow-recording
source: [06-01-SUMMARY.md, 06-02-SUMMARY.md, 06-03-SUMMARY.md, 06-04-SUMMARY.md]
started: 2026-03-07T00:00:00Z
updated: 2026-03-07T12:00:00Z
gaps_resolved_by: 06-05-PLAN.md
---

## Current Test

[testing complete]

## Tests

### 1. Set personal best in settings
expected: Visit /settings. You should see a "Settings" heading and a form to enter your personal best peak flow (L/min). Enter 520, submit. The page should reload showing "520 L/min" as your current personal best with a date.
result: pass

### 2. Personal best validation
expected: On /settings, try submitting a value of 50 (below the 100 minimum). An inline error should appear — no page redirect. The current personal best should remain unchanged.
result: pass

### 3. Banner when no personal best set
expected: From a fresh account with no personal best set, visit /peak-flow-readings/new. A yellow/amber banner should appear above the form warning you to set your personal best first, with a link to /settings.
result: pass

### 4. No banner when personal best is set
expected: With a personal best already set (e.g. 520 L/min), visit /peak-flow-readings/new. The yellow banner should NOT appear — just the entry form.
result: pass

### 5. Record a peak flow reading — Green zone
expected: With a personal best of 520 L/min set, enter a value of 442 (85% of 520 → Green Zone) and submit. A flash message should appear saying "Reading saved — Green Zone (85% of personal best)." — without a full page reload. The form should reset.
result: pass

### 6. Zone flash with no personal best
expected: Delete your personal best (or test from an account with none set), then record any reading (e.g. 400). The flash should say something like "Reading saved — set your personal best to see your zone." No zone colour shown.
result: issue
reported: "Pass, but it didn't show the actual colour when there was a personal best set. It just mentioned the name of the colour (Yellow)"
severity: minor

### 7. Peak flow reading validation
expected: On /peak-flow-readings/new, clear the value field and submit. An inline validation error should appear — the form stays put, no redirect. Try submitting 950 (above max 900) — also shows an error.
result: issue
reported: "If I try submitting nothing, there is no warning. Over 900, then there is a warning"
severity: major

### 8. Form resets after successful recording
expected: Submit a valid reading. The value field should clear back to empty and the datetime should reset to current time — ready for another entry — without a full page reload.
result: issue
reported: "No, the form didn't clear and the previous message about reading saved remained and another appeared below it"
severity: major

## Summary

total: 8
passed: 5
issues: 3
pending: 0
skipped: 0

## Gaps

- truth: "Submitting a blank value on the peak flow entry form shows an inline validation error"
  status: failed
  reason: "User reported: If I try submitting nothing, there is no warning. Over 900, then there is a warning"
  severity: major
  test: 7
  root_cause: "number_field :value in _form.html.erb is missing required: true. Without it, an empty number input passes browser constraint validation (min/max only apply to non-empty values). Turbo's XHR path bypasses browser tooltips, so the blank value reaches the server where Rails casts it to nil and presence: true fires — but the errors ARE returned in the turbo stream replace. The visual failure is that the errors block may not be rendering visibly, or more likely the server round-trip is not completing because the turbo frame structure breaks after first replace (see gap 3)."
  artifacts:
    - path: "app/views/peak_flow_readings/_form.html.erb"
      issue: "number_field :value has min: 1, max: 900 but no required: true"
  missing:
    - "Add required: true to number_field :value in _form.html.erb"
  debug_session: ".ariadna_planning/debug/peak-flow-blank-silent-fail.md"

- truth: "Zone flash message shows the zone colour visually (green/yellow/red) alongside the zone name when a reading is saved with a personal best set"
  status: failed
  reason: "User reported: Pass, but it didn't show the actual colour when there was a personal best set. It just mentioned the name of the colour (Yellow)"
  severity: minor
  test: 6
  root_cause: "Three gaps combine: (1) zone_flash_message returns plain text with no HTML span; (2) <%= %> in create.turbo_stream.erb and application.html.erb HTML-escape any HTML returned; (3) no CSS classes for zone colours exist in peak_flow.css. All three must be fixed together."
  artifacts:
    - path: "app/controllers/peak_flow_readings_controller.rb"
      issue: "zone_flash_message returns plain text — no <span> with colour class"
    - path: "app/views/peak_flow_readings/create.turbo_stream.erb"
      issue: "<%= @flash_message %> escapes HTML"
    - path: "app/assets/stylesheets/peak_flow.css"
      issue: "No .zone-label--green/yellow/red CSS classes exist"
  missing:
    - "Wrap zone name in <span class='zone-label zone-label--ZONE'> in zone_flash_message, mark html_safe"
    - "Use raw() or html_safe in create.turbo_stream.erb flash render"
    - "Add zone colour CSS classes to peak_flow.css (can reuse --severity-* custom props)"
  debug_session: ".ariadna_planning/debug/peak-flow-flash-zone-colour.md"

- truth: "After a successful recording the form resets (value clears, datetime resets) and old flash messages are replaced not accumulated"
  status: failed
  reason: "User reported: No, the form didn't clear and the previous message about reading saved remained and another appeared below it"
  severity: major
  test: 8
  root_cause: "Two independent bugs: (1) Form not clearing — create.turbo_stream.erb replace block renders the form partial without wrapping in turbo_frame_tag, so after the first replace the <turbo-frame id='peak_flow_reading_form'> element is gone from the DOM; browser form state restoration then repopulates the re-inserted inputs. (2) Flash stacking — turbo_stream.prepend is additive and the layout has no dedicated flash container with a stable DOM id to replace."
  artifacts:
    - path: "app/views/peak_flow_readings/create.turbo_stream.erb"
      issue: "replace block renders form partial without turbo_frame_tag wrapper; uses prepend for flash instead of replace"
    - path: "app/views/layouts/application.html.erb"
      issue: "No dedicated <div id='flash-messages'> wrapper — flash <p> tags are direct children of <main>"
  missing:
    - "Wrap rendered form in turbo_frame_tag 'peak_flow_reading_form' inside the replace block in create.turbo_stream.erb"
    - "Add <div id='flash-messages'> wrapper in application.html.erb around flash notices"
    - "Change turbo_stream.prepend 'main-content' to turbo_stream.replace 'flash-messages' in create.turbo_stream.erb"
  debug_session: ".ariadna_planning/debug/peak-flow-form-flash-bugs.md"
