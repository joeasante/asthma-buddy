---
status: pending
priority: p3
issue_id: "183"
tags: [code-review, css, dashboard, dead-code]
dependencies: []
---

# dash-recent-row--symptom Modifier Applied in Dashboard But Not Defined in CSS

## Problem Statement
dashboard/index.html.erb line 289 applies `dash-recent-row--symptom` as a class on symptom log rows alongside the severity modifier. No CSS rule exists for this class in dashboard.css. It is harmless at runtime but represents dead class vocabulary — a developer looking at the CSS will not find it.

## Proposed Solutions

### Option A
Either add `.dash-recent-row--symptom { }` as a documented empty rule in dashboard.css (as a type discriminator for future use), or remove the class from the template.
- Effort: Small
- Risk: None

## Recommended Action

## Technical Details
- Affected files: app/views/dashboard/index.html.erb, app/assets/stylesheets/dashboard.css

## Acceptance Criteria
- [ ] Either `.dash-recent-row--symptom` is defined in dashboard.css, or the class is removed from the template
- [ ] No orphaned class references remain after the change

## Work Log
- 2026-03-10: Created via code review
