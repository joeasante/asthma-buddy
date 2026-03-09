---
status: pending
priority: p3
issue_id: "142"
tags: [code-review, css, cleanup]
dependencies: []
---

# Orphaned `--color-*` CSS Legacy Aliases Have Zero Consumers

## Problem Statement

`application.css` defines 10 `--color-*` legacy token aliases (lines 63–72) with zero consumers anywhere in the codebase. They add dead definitions that will silently diverge as canonical tokens are updated.

Flagged by: pattern-recognition-specialist.

## Findings

**File:** `app/assets/stylesheets/application.css`, lines 63–72

```css
/* Legacy aliases — keep for compatibility */
--color-brand:        var(--brand);
--color-brand-hover:  var(--brand-dark);
--color-text:         var(--text);
--color-text-muted:   var(--text-3);
--color-text-subtle:  var(--text-4);
--color-border:       var(--border);
--color-border-light: var(--gray-100);
--color-surface:      var(--surface);
--color-surface-alt:  var(--surface-alt);
--color-bg:           var(--bg);
```

Grep across all CSS files confirms: none of these `--color-*` tokens are referenced anywhere else.

## Proposed Solution

Delete the entire `--color-*` alias block from `application.css`. If they were added for a future use case that hasn't materialized, YAGNI applies.

## Acceptance Criteria

- [ ] `--color-*` alias block removed from `application.css`
- [ ] No visual regressions (grep confirms no consumers before deleting)
- [ ] CSS still compiles without errors

## Work Log

- 2026-03-08: Identified by pattern-recognition-specialist
