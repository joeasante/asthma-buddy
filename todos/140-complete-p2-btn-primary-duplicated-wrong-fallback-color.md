---
status: pending
priority: p2
issue_id: "140"
tags: [code-review, css, design]
dependencies: []
---

# `.btn-primary` Duplicated in `peak_flow.css` with Wrong Fallback Color

## Problem Statement

`.btn-primary` is defined in both `application.css` and `peak_flow.css`. The `peak_flow.css` definition wins via CSS cascade and has wrong values: `var(--brand, #059669)` uses green (`#059669`, Tailwind `green-600`) as the fallback color instead of brand blue, and uses `--radius-md` instead of `--radius-lg`. On pages that load `peak_flow.css`, all primary buttons get incorrect styling.

Flagged by: pattern-recognition-specialist (medium severity).

## Findings

**`app/assets/stylesheets/application.css`:**
```css
.btn-primary {
  background: var(--brand);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  ...
}
```

**`app/assets/stylesheets/peak_flow.css`:**
```css
.btn-primary {
  background: var(--brand, #059669);   /* Wrong: green fallback */
  border-radius: var(--radius-md, 8px); /* Wrong: smaller radius */
  box-shadow: 0 1px 3px rgba(37, 99, 235, 0.3); /* Hardcoded */
  ...
}
```

The `#059669` fallback is almost certainly a copy-paste artifact from a different project.

## Proposed Solution

Delete the entire `.btn-primary` block from `peak_flow.css`. The definition in `application.css` is already globally available and correct.

If `peak_flow.css` needs any peak-flow-specific overrides to `.btn-primary`, use a more specific selector like `.peak-flow .btn-primary` rather than redefining the base class.

## Acceptance Criteria

- [ ] `.btn-primary` definition removed from `peak_flow.css`
- [ ] All primary buttons on the peak flow page render with correct brand blue color
- [ ] No visual regressions on other pages
- [ ] Manual check: peak flow page `Submit` button uses `--brand` color (blue, not green)

## Work Log

- 2026-03-08: Identified by pattern-recognition-specialist
