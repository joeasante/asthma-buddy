---
status: complete
phase: 25-clinical-intelligence
source: [25-03-SUMMARY.md, 25-04-SUMMARY.md]
started: 2026-03-14T10:30:00Z
updated: 2026-03-14T11:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Zone-coloured insight card on dashboard
expected: Dashboard shows a zone-coloured insight card (not italic text) before the stats grid with icon and interpretation text. Colour matches zone. No card if no readings.
result: pass

### 2. GP Summary button in page header
expected: "GP Summary" button in page header navigates to /appointment-summary. Old bottom link gone.
result: issue
reported: "Is GP Summary a good name? Styling should match page header icon pattern, not look like a standalone button."
severity: cosmetic

### 3. Appointment summary — individual peak flow readings
expected: Peak Flow section shows individual readings table with date, time of day, value, and zone.
result: issue
reported: "Zone colours need legend for GPs. Notes truncated — should show full content. GINA Threshold is jargon. Medications should show sick-day dose. Temporary courses (steroids) from the period should be listed."
severity: major

### 4. Appointment summary — individual symptom records
expected: Symptoms section shows individual records with type, severity, date, and notes.
result: issue
reported: "See test 3 notes. Also, 'Appointment Summary' is the wrong page title — sounds like a summary of an attended appointment, not a report to bring to one."
severity: major

### 5. Appointment summary — reliever dose detail
expected: Reliever Use section shows individual dose log entries with medication name, puffs, and date/time.
result: issue
reported: "See test 3 notes — same issues apply."
severity: major

### 6. Appointment summary — health event detail
expected: Health Events section shows event type, start date, duration/status, and notes.
result: issue
reported: "See test 3 notes — same issues apply."
severity: major

### 7. Print layout fix
expected: Print preview well-packed, no large empty gap on first page.
result: issue
reported: "Better but first page still has very little on it. See test 3 notes."
severity: minor

### 8. PB aging threshold at 12 months
expected: PB aging alert triggers at 12 months (not 18).
result: skipped
reason: Application has not been available long enough to reach the threshold

## Summary

total: 8
passed: 1
issues: 6
pending: 0
skipped: 1

## Gaps

- truth: "Dashboard header button has appropriate name and matches page header icon styling"
  status: failed
  reason: "User reported: 'GP Summary' is not a good name. Styling should match page header icon pattern."
  severity: cosmetic
  test: 2
  root_cause: "Button text 'GP Summary' uses UK-centric jargon. Styled as btn-secondary instead of matching page-header-icon link pattern."
  artifacts:
    - path: "app/views/dashboard/index.html.erb"
      issue: "GP Summary text and btn-secondary styling in page-header-actions"
  missing:
    - "Rename to '30-Day Health Report' or similar"
    - "Restyle as icon-link matching page-header pattern"

- truth: "Appointment summary provides clinically complete information for a GP"
  status: failed
  reason: "User reported: Zone colours need legend. Notes truncated. GINA Threshold is jargon. Sick-day dose missing from medications. Temporary courses from the period not shown."
  severity: major
  test: 3
  root_cause: "Multiple content gaps: (1) no zone legend explaining green/yellow/red thresholds, (2) notes truncated instead of full render, (3) 'GINA Threshold' label unclear, (4) only standard_dose_puffs shown not sick_day_dose_puffs, (5) @active_courses only shows currently-active courses not courses overlapping the 30-day period."
  artifacts:
    - path: "app/views/appointment_summaries/show.html.erb"
      issue: "No zone legend, truncated notes, GINA jargon, missing sick-day dose, missing period courses"
    - path: "app/controllers/appointment_summaries_controller.rb"
      issue: "@active_courses scoped to currently-active, not period-overlapping"
  missing:
    - "Add zone legend: Green (≥80% PB), Yellow (50-79%), Red (<50%)"
    - "Render full notes instead of truncating"
    - "Replace 'GINA Threshold' with 'Reliever use vs guideline limit (≤2/week)'"
    - "Add sick_day_dose_puffs column to medications table"
    - "Query courses that overlapped with the 30-day period (starts_on <= period_end AND ends_on >= period_start)"

- truth: "Page title accurately describes its purpose"
  status: failed
  reason: "User reported: 'Appointment Summary' sounds like a summary of an attended appointment, not a report to bring to one."
  severity: major
  test: 4
  root_cause: "Page title 'Appointment Summary' is ambiguous — implies record of past appointment rather than preparation document."
  artifacts:
    - path: "app/views/appointment_summaries/show.html.erb"
      issue: "Page title 'Appointment Summary' is misleading"
  missing:
    - "Rename page to '30-Day Health Report' or 'Health Report'"
    - "Update content_for :title, meta description, dashboard link text, route if needed"

- truth: "Print layout renders content efficiently on first page"
  status: failed
  reason: "User reported: Better but first page still has very little on it."
  severity: minor
  test: 7
  root_cause: "Page header + sparse aggregate stats section still too spread out for print. Need tighter print-specific margins and possibly inline the aggregate stats rather than full-width cards."
  artifacts:
    - path: "app/assets/stylesheets/appointment_summary.css"
      issue: "@media print spacing still too generous for page 1 density"
  missing:
    - "Further reduce print-specific padding/margins"
    - "Consider collapsing aggregate stats into a more compact inline layout for print"

## Additional feedback carried forward

- Dose log deletion: user wants time-limited deletion window and warning for accidental logs (future phase)
