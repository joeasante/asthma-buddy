---
status: pending
priority: p3
issue_id: "125"
tags: [code-review, css, design-tokens, quality, profile]
dependencies: []
---

# Raw hex values for error state in `profile.css` — no `var()` fallback

## Problem Statement

`profile.css` uses raw hex values (`#fca5a5`, `#7f1d1d`) for the error state border and text at lines 90 and 95. The rest of the file uses `var()` with fallbacks consistently. These values can't be overridden globally via design tokens.

## Findings

- `app/assets/stylesheets/profile.css:90` — `border-color: #fca5a5`
- `app/assets/stylesheets/profile.css:95` — `color: #7f1d1d`
- `application.css` has `--severity-severe: #dc2626` and `--severity-severe-bg: #fee2e2` but no border or dark-text error tokens
- Rest of `profile.css` uses `var(--border, #e5e7eb)`, `var(--text-4, #9ca3af)` etc.

## Proposed Solutions

### Option A: Add tokens to application.css and use them
Add to `:root` in `application.css`:
```css
--error-border: #fca5a5;
--error-text-dark: #7f1d1d;
```
Then in `profile.css`:
```css
border-color: var(--error-border, #fca5a5);
color: var(--error-text-dark, #7f1d1d);
```

**Effort:** Trivial | **Risk:** Low

### Option B: Reuse existing severity tokens where semantically appropriate
`#fca5a5` ≈ severity-severe's border colour. Could use `var(--severity-severe-bg, #fee2e2)` for the border if the existing tokens match closely enough.

**Effort:** Trivial | **Risk:** Low

## Recommended Action

Option A — explicit tokens are clearer.

## Technical Details

- **Affected files:** `app/assets/stylesheets/profile.css:90,95`, `app/assets/stylesheets/application.css`

## Acceptance Criteria

- [ ] Error state colours referenced via `var()` with fallbacks in `profile.css`
- [ ] Tokens defined in `application.css`

## Work Log

- 2026-03-08: Identified by pattern-recognition-specialist during PR review
