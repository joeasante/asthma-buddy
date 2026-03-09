---
status: pending
priority: p3
issue_id: "143"
tags: [code-review, css, cleanup]
dependencies: []
---

# `symptom_timeline.css` Redefines Severity Tokens Already in `application.css`

## Problem Statement

`symptom_timeline.css` has a `:root` block redefining `--severity-*` CSS custom properties that are already defined with identical values in `application.css`. The values will silently diverge if one file is updated without updating the other.

Flagged by: pattern-recognition-specialist.

## Findings

**`app/assets/stylesheets/symptom_timeline.css`**, lines 5–12:
```css
:root {
  --severity-mild:        #16a34a;
  --severity-moderate:    #d97706;
  --severity-severe:      #dc2626;
  --severity-mild-bg:     #dcfce7;
  --severity-moderate-bg: #fef3c7;
  --severity-severe-bg:   #fee2e2;
}
```

These are already defined in `application.css` with the same values.

## Proposed Solution

Remove the entire `:root` block from `symptom_timeline.css`. The tokens are globally available from `application.css`.

## Acceptance Criteria

- [ ] `:root` block removed from `symptom_timeline.css`
- [ ] Severity colors still render correctly (they come from `application.css`)
- [ ] No visual regressions

## Work Log

- 2026-03-08: Identified by pattern-recognition-specialist
