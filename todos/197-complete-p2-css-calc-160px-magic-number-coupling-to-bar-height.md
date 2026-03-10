---
status: complete
priority: p2
issue_id: "197"
tags: [code-review, css, frontend, phase-15-1]
dependencies: []
---

# CSS `calc()` Hardcodes `160px` — Silent Coupling Between Bar Height and Threshold Line

## Problem Statement
`.reliever-threshold` uses `bottom: calc(var(--space-sm) + 160px * (2 / 6))`. The `160px` is a hardcoded literal that mirrors `.reliever-bars { height: 160px }`. If a designer changes the bar chart height, the dashed GINA threshold line silently positions incorrectly. There is no connection between the two values visible in the CSS.

## Findings
- **File:** `app/assets/stylesheets/reliever_usage.css:8,17`
- Line 8: `.reliever-bars { height: 160px; }`
- Line 17: `bottom: calc(var(--space-sm) + 160px * (2 / 6));`
- Both `160px` values must be kept in sync manually
- Pattern reviewer and Rails reviewer both flagged

## Proposed Solutions

### Option A (Recommended): CSS custom property on `.reliever-bars`
```css
.reliever-bars {
  --bars-height: 160px;
  height: var(--bars-height);
  /* ... other properties */
}

.reliever-threshold {
  bottom: calc(var(--space-sm) + var(--bars-height) * (2 / 6));
}
```
- Effort: Very small
- Risk: None — behaviour unchanged, coupling made explicit

## Recommended Action

## Technical Details
- Affected files: `app/assets/stylesheets/reliever_usage.css:8,17`

## Acceptance Criteria
- [ ] A single CSS custom property `--bars-height` controls both bar container height and threshold line position
- [ ] No raw `160px` literal in `calc()` expressions

## Work Log
- 2026-03-10: Identified by kieran-rails-reviewer and pattern-recognition-specialist in Phase 15.1 review
