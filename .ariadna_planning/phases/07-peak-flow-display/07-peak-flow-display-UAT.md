---
status: diagnosed
phase: 07-peak-flow-display
source: [07-01-SUMMARY.md, 07-02-SUMMARY.md, 07-03-SUMMARY.md, 07-04-SUMMARY.md]
started: 2026-03-07T21:00:00Z
updated: 2026-03-07T21:10:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Peak Flow nav link
expected: When logged in, the navigation bar includes a "Peak Flow" link visible alongside other nav items.
result: issue
reported: "Not seeing any nav bar items. It looks completely unstyled"
severity: major

### 2. Peak flow readings index
expected: Visiting /peak-flow-readings shows a list of readings. Each row displays the L/min value, a coloured zone badge pill (green/yellow/red), and a timestamp.
result: issue
reported: "It does, but it is all very small and looks rubbish. There is no real styling, borders, nav menu or anything really. It's mainly plain white with really small fonts. It looks completely unfinished."
severity: major

### 3. Zone badge colours
expected: Readings in the green zone show a green pill badge, yellow zone readings show a yellow pill badge, and red zone readings show a red pill badge. Badges are visually distinct without needing to read the label.
result: skipped
reason: Skipped due to global CSS not loading — will retest after styling is fixed

### 4. Date filter chips (7/30/90/all)
expected: The filter bar shows preset chips: 7 days, 30 days, 90 days, all. Clicking a chip updates the list without a full page reload (Turbo Frame). The active chip appears visually selected.
result: pass

### 5. Custom date range filter
expected: A custom date range form is available alongside the preset chips. Entering start/end dates and submitting filters the list to that range without a full page reload.
result: pass

### 6. Pagination
expected: If there are more than 25 readings, Prev/Next navigation appears at the bottom of the list with a page position indicator (e.g. "Page 1 of 3").
result: skipped
reason: Fewer than 25 readings in test data

### 7. Edit a peak flow reading
expected: Each reading row has an Edit link. Clicking it replaces the row inline with an edit form (no full page navigation). Updating the value and saving replaces the form with the updated row showing the recalculated zone badge.
result: pass

### 8. Delete a peak flow reading
expected: Each reading row has a Delete button. Clicking it opens a confirmation dialog. Confirming removes the reading from the list without a page reload.
result: pass

### 9. Empty state
expected: If there are no readings (or none match the current filter), an empty state message is shown instead of a blank list.
result: pass

## Summary

total: 9
passed: 5
issues: 2
pending: 0
skipped: 2

## Gaps

- truth: "When logged in, the navigation bar includes a 'Peak Flow' link visible alongside other nav items."
  status: failed
  reason: "User reported: Not seeing any nav bar items. It looks completely unstyled"
  severity: major
  test: 1
  root_cause: "application.css is empty (comments only) — no base styles, typography, or layout CSS exists. The layout references classes (nav-brand, nav-link, nav-auth, nav-user-email, btn-sign-out, flash, flash--notice, flash--alert) that are defined in no stylesheet. Propshaft serves each CSS file independently; without @import or a global stylesheet, feature CSS loads but global layout never does."
  artifacts:
    - path: "app/assets/stylesheets/application.css"
      issue: "Completely empty — only a comment block, no CSS rules or @imports"
    - path: "app/views/layouts/application.html.erb"
      issue: "References 8+ CSS classes (nav-brand, nav-link, nav-auth, etc.) that do not exist in any stylesheet"
  missing:
    - "Global stylesheet with base typography, body/header/footer/main layout, and navigation styles"
    - "CSS rules for .nav-brand, .nav-link, .nav-auth, .nav-user-email, .btn-sign-out"
    - "CSS rules for .flash, .flash--notice, .flash--alert"
  debug_session: ""
- truth: "Peak flow readings index shows rows with L/min value, coloured zone badge pill, and timestamp with proper styling."
  status: failed
  reason: "User reported: It does, but it is all very small and looks rubbish. There is no real styling, borders, nav menu or anything really. It's mainly plain white with really small fonts. It looks completely unfinished."
  severity: major
  test: 2
  root_cause: "Same root cause as test 1 — no global base stylesheet. Without body font-size, line-height, spacing, or layout rules, every page renders with browser defaults (tiny Times New Roman, no spacing, plain white)."
  artifacts:
    - path: "app/assets/stylesheets/application.css"
      issue: "No base typography or page layout styles"
  missing:
    - "Base font, line-height, colour palette, spacing scale in application.css"
    - "Page-level layout rules (body, main, container, header, footer)"
  debug_session: ""
