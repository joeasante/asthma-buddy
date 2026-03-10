---
status: pending
priority: p3
issue_id: "184"
tags: [code-review, css, duplication, cleanup]
dependencies: []
---

# @keyframes skeleton-sweep Defined Identically in Two Stylesheets

## Problem Statement
`@keyframes skeleton-sweep` is defined inside `@media (prefers-reduced-motion: no-preference)` in both peak_flow.css (lines 687-690) and symptom_timeline.css (lines 189-192). Definitions are identical. The second overrides the first in cascade order — no functional defect — but they could diverge in future. The canonical definition belongs in application.css as a shared animation. The `.skeleton` class rule that uses it should also move to application.css if it's shared.

## Proposed Solutions

### Option A
Move `@keyframes skeleton-sweep` and the `.skeleton` animated style block to application.css inside `@media (prefers-reduced-motion: no-preference)`. Remove the duplicates from peak_flow.css and symptom_timeline.css.
- Effort: Small
- Risk: Low (verify skeleton animation still works in both pages)

## Recommended Action

## Technical Details
- Affected files: app/assets/stylesheets/peak_flow.css, app/assets/stylesheets/symptom_timeline.css, app/assets/stylesheets/application.css

## Acceptance Criteria
- [ ] `@keyframes skeleton-sweep` defined exactly once in application.css
- [ ] Duplicate definitions removed from peak_flow.css and symptom_timeline.css
- [ ] Skeleton loading animation still renders correctly on the peak flow index and symptom timeline pages
- [ ] `prefers-reduced-motion` guard is preserved in application.css

## Work Log
- 2026-03-10: Created via code review
