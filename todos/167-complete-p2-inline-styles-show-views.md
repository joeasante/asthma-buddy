---
status: pending
priority: p2
issue_id: "167"
tags: [code-review, css, design-system, show-pages]
dependencies: []
---

# Inline style= Attributes Throughout Show Views Violate Design System

## Problem Statement
`peak_flow_readings/show.html.erb` has 12+ inline `style=` attributes. `symptom_logs/show.html.erb` and `health_events/show.html.erb` also use inline styles. Every other view in the codebase uses CSS classes exclusively. The `<dl>/<dt>/<dd>` layout pattern is duplicated inline across both peak_flow and health_event show views, which is a clear candidate for shared CSS classes.

Additionally, `pf-row-value` and `pf-row-unit` are dead class names from the old table layout — no CSS definition exists for either. The inline styles on those spans override what those classes should provide, masking the fact that the classes are dead.

## Findings
- `app/views/peak_flow_readings/show.html.erb`: 12+ inline `style=` attributes covering layout, spacing, typography, and colour
- `app/views/symptom_logs/show.html.erb`: inline styles present
- `app/views/health_events/show.html.erb`: inline styles present; `<dl>/<dt>/<dd>` pattern mirrors peak_flow show without shared classes
- `pf-row-value` and `pf-row-unit` class references exist in the peak_flow show view with no corresponding CSS rule — dead class names from a prior table-based layout

## Proposed Solutions

### Option A
Create shared `.detail-list`, `.detail-row`, `.detail-term`, `.detail-value` classes in `application.css` to cover the `<dl>/<dt>/<dd>` pattern used across show views. Create `.pf-show-hero-row`, `.pf-show-hero-value`, `.pf-show-hero-unit` in `peak_flow.css` for the peak flow hero value display. Remove all inline `style=` attributes from all three show views. Remove dead `pf-row-value`/`pf-row-unit` class references and replace with the correct new classes.
- Pros: Eliminates all inline styles; makes `<dl>` pattern reusable across future show views; removes dead class noise; consistent with rest of codebase
- Cons: Requires touching three view files and two stylesheet files
- Effort: Medium
- Risk: Low

## Recommended Action

## Technical Details
- Affected files:
  - `app/views/peak_flow_readings/show.html.erb`
  - `app/views/symptom_logs/show.html.erb`
  - `app/views/health_events/show.html.erb`
  - `app/assets/stylesheets/application.css`
  - `app/assets/stylesheets/peak_flow.css`
  - `app/assets/stylesheets/symptom_timeline.css`

## Acceptance Criteria
- [ ] Zero `style=` attributes in any show view
- [ ] All `<dl>` layouts across show views use shared `.detail-list`, `.detail-row`, `.detail-term`, `.detail-value` classes
- [ ] `pf-row-value` and `pf-row-unit` class references removed from all views
- [ ] New CSS classes defined in appropriate stylesheet files (shared in `application.css`, peak-flow-specific in `peak_flow.css`)
- [ ] No visual regressions on any show page

## Work Log
- 2026-03-10: Created via code review
