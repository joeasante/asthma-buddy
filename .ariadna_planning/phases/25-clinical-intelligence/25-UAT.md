---
status: complete
phase: 25-clinical-intelligence
source: [25-05-SUMMARY.md]
started: 2026-03-14T12:00:00Z
updated: 2026-03-14T12:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Page renamed to 30-Day Health Report
expected: /health-report shows page titled "30-Day Health Report". Old /appointment-summary redirects.
result: pass

### 2. Dashboard link renamed and restyled
expected: "Health Report" icon-link in dashboard page header navigates to /health-report.
result: pass

### 3. Zone legend in Peak Flow section
expected: Zone legend below zone table: Green (≥80%), Yellow (50–79%), Red (<50%).
result: issue
reported: "Peak flow section is very cramped. Needs better separation between sections and more space. Legend cramped. Same applies to rest of page. Doesn't look good on mobile, particularly notes sections. Is sick day dose appropriate for courses?"
severity: major

### 4. Full notes (no truncation)
expected: Full notes shown, not truncated.
result: pass

### 5. Guideline limit replaces GINA jargon
expected: Plain language instead of "GINA threshold".
result: issue
reported: "Do we need 'Guideline limit'? Can't it just say 'Within range' or 'Above range'? Is the line below it needed?"
severity: minor

### 6. Sick-day dose in medications table
expected: Sick-day dose column in medications table.
result: pass

### 7. Period-overlapping courses shown
expected: Courses active during the 30-day period appear in subsection.
result: pass

### 8. Print layout tighter
expected: First page has meaningful content, no large gaps.
result: pass

### 9. Mobile view — dashboard header link
expected: "Health Report" link displays cleanly on mobile.
result: issue
reported: "It appears underneath 'your health at a glance' and looks stupid."
severity: major

### 10. Mobile view — Print button on Health Report
expected: Print button displays cleanly on mobile.
result: issue
reported: "It appears underneath 'Last 30 days', looks stupid, and the button is far too big."
severity: major

## Summary

total: 10
passed: 6
issues: 4
pending: 0
skipped: 0

## Gaps

- truth: "Health report page has comfortable spacing between sections and readable layout on all viewports"
  status: failed
  reason: "User reported: sections very cramped, needs better separation, legend cramped, doesn't look good on mobile especially notes. Sick-day dose column should not apply to courses."
  severity: major
  test: 3
  root_cause: "Print-tightening CSS may be leaking into screen styles. Section gaps, legend padding, and notes column widths insufficient for mobile. Courses subsection incorrectly shows sick-day dose column."
  artifacts:
    - path: "app/assets/stylesheets/appointment_summary.css"
      issue: "Section gaps and legend padding too tight for screen view; mobile responsive rules missing"
    - path: "app/views/appointment_summaries/show.html.erb"
      issue: "Courses table includes sick-day dose column — should be excluded"
  missing:
    - "Increase section gaps and legend padding for screen (not print)"
    - "Add mobile responsive rules for notes cells (word-break, min-width)"
    - "Remove sick-day dose column from courses subsection"

- truth: "Reliever threshold label is plain and self-explanatory"
  status: failed
  reason: "User reported: 'Guideline limit' still jargon-ish. Just say 'Within range' or 'Above range'. Remove explanatory line if redundant."
  severity: minor
  test: 5
  root_cause: "'Guideline limit' label still references external standards. Should be self-contained status: 'Within range (≤2/week)' or 'Above range (>2/week)'."
  artifacts:
    - path: "app/views/appointment_summaries/show.html.erb"
      issue: "'Guideline limit' label and explanatory text"
  missing:
    - "Replace 'Guideline limit' with 'Within range (≤2/week)' or 'Above range (>2/week)'"
    - "Remove redundant explanatory line beneath"

- truth: "Dashboard Health Report link displays cleanly on mobile"
  status: failed
  reason: "User reported: appears underneath 'your health at a glance' and looks stupid."
  severity: major
  test: 9
  root_cause: "page-header-actions wraps below page-header-left on narrow viewports. No mobile-specific rule to hide or reposition the Health Report link."
  artifacts:
    - path: "app/views/dashboard/index.html.erb"
      issue: "Health Report link in page-header-actions wraps awkwardly on mobile"
    - path: "app/assets/stylesheets/dashboard.css"
      issue: "No @media rule for page-header-actions on small screens"
  missing:
    - "Hide Health Report link on mobile (display:none below 768px) — feature is desktop/print oriented"
    - "Or move to a different mobile-appropriate location"

- truth: "Health Report print button displays cleanly on mobile"
  status: failed
  reason: "User reported: appears underneath 'Last 30 days', looks stupid, button far too big."
  severity: major
  test: 10
  root_cause: "page-header-actions on health report wraps below subtitle on mobile. btn-secondary is full desktop size with no mobile reduction."
  artifacts:
    - path: "app/views/appointment_summaries/show.html.erb"
      issue: "Print button in page-header-actions wraps on mobile"
    - path: "app/assets/stylesheets/appointment_summary.css"
      issue: "No mobile-specific rule for print button sizing or visibility"
  missing:
    - "Hide print button on mobile (display:none below 768px) — printing from mobile is impractical"
    - "Or reduce to small icon-only button on mobile"
