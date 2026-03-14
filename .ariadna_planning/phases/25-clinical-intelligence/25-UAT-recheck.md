---
status: complete
phase: 25-clinical-intelligence
source: [25-06-SUMMARY.md]
started: 2026-03-14T13:00:00Z
updated: 2026-03-14T13:15:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Screen spacing between sections
expected: Visit /health-report on desktop. Sections have comfortable spacing. Zone legend has background/padding and is not cramped.
result: issue
reported: "Dashboard link to Health Report — unclear how to access it. Peak flow readings need time column. Symptoms entries need more separation and notes don't wrap well on mobile — notes should be underneath rows, not a side column. Dose log should show Preventer/Reliever type instead of actual medication name. Health Events entries have same issue as symptoms — notes should be underneath. Overall: multiple detail table layout issues."
severity: major

### 2. Courses table — no sick-day dose column
expected: In the Medications section, the "Courses during period" table has 4 columns: Name, Type, Dose, Dates. No "Sick day dose" column.
result: issue
reported: "Dose column says 'puffs' but course medication is tablets (e.g. prednisolone). Also no way to enter daily dose count (e.g. 6 per day) when adding a course."
severity: major

### 3. Reliever status label — plain language
expected: In the Reliever Usage section, the third stat says "Status" with value "Within range (<=2/week)" or "Above range (>2/week)". No "Guideline limit" label. No explanatory paragraph below the stats.
result: issue
reported: "Label is correct but looks poor on mobile and far too big."
severity: cosmetic

### 4. Mobile — dashboard Health Report link hidden
expected: Resize browser to mobile width (<768px) on /dashboard. The "Health Report" link in the page header is NOT visible — it's hidden on mobile.
result: pass
note: "User confirmed hidden, but asked how to access Health Report on mobile — no mobile route exists."

### 5. Mobile — print button hidden on Health Report
expected: Resize to mobile width (<768px) on /health-report. The print button is NOT visible — hidden on mobile since printing from phones is impractical.
result: pass
note: "User confirmed hidden, but button still too big on desktop — should be icon-styled like other page header actions. Also raised same mobile accessibility question."

### 6. Mobile — notes cells wrap properly
expected: On /health-report at mobile width, any notes content in detail tables wraps within cells (no horizontal overflow breaking the layout). Tables may scroll horizontally if needed.
result: issue
reported: "Long notes really need to sit underneath and not to the side, because they make the rows really big. Still not enough separation between individual records."
severity: major

## Summary

total: 6
passed: 2
issues: 4
pending: 0
skipped: 0

## Gaps

- truth: "Health Report detail tables have good mobile layout with notes accessible"
  status: failed
  reason: "User reported: peak flow readings need time. Symptoms and health events need more separation between entries, notes should be underneath rows not in a side column (especially mobile). Dose log should show medication type (Preventer/Reliever) not medication name. Dashboard link to Health Report unclear."
  severity: major
  test: 1
  artifacts:
    - path: "app/views/appointment_summaries/show.html.erb"
      issue: "Symptoms table has notes as side column — should be stacked underneath on mobile. Same for Health Events. Dose log shows medication name instead of type. Peak flow individual readings missing time."
  missing:
    - "Mobile-responsive stacked layout for detail table rows with notes underneath"
    - "Show medication type (Preventer/Reliever) in dose log instead of medication name"
    - "Add time to peak flow individual readings"
    - "Better visual separation between detail table entries"

- truth: "Courses table displays correct units and allows daily dose entry"
  status: failed
  reason: "User reported: dose column says 'puffs' but course medication is tablets (e.g. prednisolone). No way to enter daily dose count (6/day) when adding a course."
  severity: major
  test: 2
  artifacts:
    - path: "app/views/appointment_summaries/show.html.erb"
      issue: "Hardcoded 'puff/puffs' unit — tablets-based courses display wrong unit"
    - path: "app/models/medication.rb"
      issue: "No dose_unit field to distinguish puffs vs tablets"
    - path: "app/views/settings/medications/_form.html.erb"
      issue: "Course form missing daily dose frequency field"
  missing:
    - "Add dose_unit column to medications (puffs/tablets/ml) with default 'puffs'"
    - "Display correct unit in Health Report based on medication's dose_unit"
    - "Add doses_per_day field to course medication form"

- truth: "Reliever status stats display well on mobile"
  status: failed
  reason: "User reported: label is correct but looks poor on mobile and far too big."
  severity: cosmetic
  test: 3
  artifacts:
    - path: "app/assets/stylesheets/appointment_summary.css"
      issue: "appt-stats-grid and appt-stat not responsive enough on mobile — text too large"
  missing:
    - "Reduce stat font size on mobile or stack stats vertically below 768px"

- truth: "Health Report is accessible on mobile"
  status: failed
  reason: "User reported: dashboard link hidden on mobile (pass) but no alternative mobile route. Print button hidden (pass) but too big on desktop — should be icon-styled. No way to reach Health Report from mobile at all."
  severity: major
  test: 4
  artifacts:
    - path: "app/assets/stylesheets/dashboard.css"
      issue: "Health Report link hidden on mobile with no alternative"
    - path: "app/views/appointment_summaries/show.html.erb"
      issue: "Print button uses btn-secondary — should be icon-style matching page header pattern"
  missing:
    - "Add Health Report link accessible on mobile (e.g. dashboard card, settings link, or bottom nav)"
    - "Restyle print button as icon-style matching other page header actions"

- truth: "Notes display underneath records on mobile, with clear separation between entries"
  status: failed
  reason: "User reported: long notes really need to sit underneath not to the side — they make rows really big. Still not enough separation between individual records."
  severity: major
  test: 6
  artifacts:
    - path: "app/views/appointment_summaries/show.html.erb"
      issue: "Notes column in detail tables renders inline alongside other columns"
    - path: "app/assets/stylesheets/appointment_summary.css"
      issue: "No card/stacked layout for detail table rows; insufficient row separation"
  missing:
    - "Convert detail tables to card-based stacked layout on mobile — notes below other fields"
    - "Add visible row separation (border, spacing, or alternating background)"
