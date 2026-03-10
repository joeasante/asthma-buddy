---
status: complete
priority: p2
issue_id: "199"
tags: [code-review, css, design-system, frontend, phase-15-1]
dependencies: []
---

# Inline `style="height: N%"` on Bar Fills Violates Design System Convention

## Problem Statement
The bar chart renders fills with inline styles: `style="height: <%= fill_pct %>%;"`. The project design system rule is that all styling must use CSS custom properties and classes — inline style attributes escape the token system and make future theme changes harder. Dynamic values should be applied via CSS custom properties (`style="--bar-height: N%"`) with the actual CSS property in the stylesheet.

Past pattern established in todo 167 (`inline-styles-show-views`) confirms this as a project-level violation.

## Findings
- **File:** `app/views/reliever_usage/index.html.erb:102`
- `style="height: <%= fill_pct %>%;"` — raw inline style
- Learnings researcher surfaced todo 167 as directly applicable: "Use CSS custom properties (`style="--bar-height: #{percentage}%"`) instead of raw `style=` attributes"
- Pattern reviewer noted inline `style="margin-top: var(--space-sm);"` at line 137 as second occurrence

## Proposed Solutions

### Option A (Recommended): CSS custom property for bar height
In the view:
```erb
<div class="reliever-bar-fill reliever-bar-fill--<%= week[:band] %>"
     style="--bar-fill-height: <%= fill_pct %>%;"
     aria-label="...">
</div>
```
In `reliever_usage.css`:
```css
.reliever-bar-fill {
  height: var(--bar-fill-height, 0%);
  /* existing properties */
}
```
- Effort: Small
- Risk: None — identical visual output

### Option B (For line 137 correlation subtitle): Use existing utility class
Replace `<p class="page-header-subtitle" style="margin-top: var(--space-sm);">` with a semantic class modifier or the closest existing spacing utility. No inline styles.
- Effort: Very small
- Risk: None

## Recommended Action

## Technical Details
- Affected files: `app/views/reliever_usage/index.html.erb:102,137`, `app/assets/stylesheets/reliever_usage.css`
- Related: todo 167 (inline-styles-show-views — complete)

## Acceptance Criteria
- [ ] No `style="height: ..."` in the ERB template
- [ ] Bar fill height driven by `--bar-fill-height` CSS custom property
- [ ] No inline margin override on correlation subtitle
- [ ] Visual output unchanged

## Work Log
- 2026-03-10: Identified by learnings-researcher (surfacing todo 167) and pattern-recognition-specialist in Phase 15.1 review
