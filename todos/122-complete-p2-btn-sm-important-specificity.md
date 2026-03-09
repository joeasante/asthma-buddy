---
status: pending
priority: p2
issue_id: "122"
tags: [code-review, css, quality, profile, design-system]
dependencies: []
---

# `!important` on `.btn-sm` breaks specificity chain — use combined selector instead

## Problem Statement

`profile.css` declares `.btn-sm` with `!important` on `padding` and `font-size` to override `.btn-secondary`. `!important` in first-party CSS indicates a broken specificity chain. Every other `!important` in this codebase is used for unavoidable third-party overrides (Lexxy editor, ActionText). Using it on a utility modifier class is an anti-pattern.

## Findings

- `app/assets/stylesheets/profile.css:82-85`:
  ```css
  .btn-sm {
    padding: 0.375rem 0.875rem !important;
    font-size: 0.875rem !important;
  }
  ```
- `app/assets/stylesheets/application.css` — `.btn-secondary { padding: 0.75rem 1.5rem; font-size: 1rem; }` — needs to be overridden, hence the `!important`

## Proposed Solutions

### Option A: Combined selector (Recommended)
```css
.btn-secondary.btn-sm,
.btn-primary.btn-sm {
  padding: 0.375rem 0.875rem;
  font-size: 0.875rem;
}
```
Higher specificity than either `.btn-secondary` or `.btn-sm` alone; no `!important` needed.

**Effort:** Trivial | **Risk:** Low

## Recommended Action

Option A.

## Technical Details

- **Affected file:** `app/assets/stylesheets/profile.css:82-85`

## Acceptance Criteria

- [ ] `.btn-sm` declaration has no `!important`
- [ ] Profile page buttons still render at the smaller size

## Work Log

- 2026-03-08: Identified by pattern-recognition-specialist during PR review
