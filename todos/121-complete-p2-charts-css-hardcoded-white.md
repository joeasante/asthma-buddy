---
status: pending
priority: p2
issue_id: "121"
tags: [code-review, css, design-tokens, charts, quality]
dependencies: []
---

# `charts.css` uses `#ffffff` instead of `var(--surface)` — breaks if theming applied

## Problem Statement

`.chart-section` in `charts.css` uses `background: #ffffff` instead of `background: var(--surface)`. Every other card-like surface in the codebase uses the `--surface` design token. This will silently diverge from the design system if a theme or dark mode is ever applied.

## Findings

- `app/assets/stylesheets/charts.css:4` — `background: #ffffff`
- `app/assets/stylesheets/profile.css:11` — `background: var(--surface, #ffffff)` — correct
- `app/assets/stylesheets/application.css` — `--surface: #ffffff` defined

## Proposed Solutions

### Option A: Replace with design token
```css
.chart-section {
  background: var(--surface, #ffffff);
  ...
}
```
**Effort:** Trivial | **Risk:** Low

## Recommended Action

Option A.

## Technical Details

- **Affected file:** `app/assets/stylesheets/charts.css:4`

## Acceptance Criteria

- [ ] `.chart-section` uses `var(--surface, #ffffff)` not a raw hex value

## Work Log

- 2026-03-08: Identified by pattern-recognition-specialist during PR review
