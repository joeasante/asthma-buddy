---
status: complete
priority: p2
issue_id: "200"
tags: [code-review, css, naming, frontend, phase-15-1]
dependencies: []
---

# `adherence-toggle` CSS Class Borrowed in Reliever Usage View — Cross-Feature Coupling

## Problem Statement
`reliever_usage/index.html.erb` uses `<div class="adherence-toggle">` (line 68) for the period toggle. This class is named after and semantically belongs to the adherence feature. Using it in a different feature creates a hidden coupling: any future changes to `.adherence-toggle` styling silently affect the reliever usage page. The project's naming convention namespaces CSS classes by feature (`pf-*`, `dash-*`, `event-*`, `reliever-*`).

## Findings
- **File:** `app/views/reliever_usage/index.html.erb:68`
- `<div class="adherence-toggle" ...>` — wrong feature namespace
- `.adherence-toggle` is defined in `application.css` at line ~1699
- Pattern reviewer rated this Medium severity

## Proposed Solutions

### Option A (Recommended): Rename to generic class or reliever namespace
Option 1 — generic: rename `.adherence-toggle` to `.period-toggle` in `application.css` and update both views. Makes the class reusable without feature coupling.

Option 2 — reliever namespace: add `.reliever-toggle` to `reliever_usage.css` that either extends or redefines the toggle styles. Less reusable but fully isolated.
- Effort: Small
- Risk: Low (CSS rename; update both usages)

### Option B: Leave as-is and add comment
Add `<%# Shared toggle class — see application.css %>` as a comment. Acknowledges the coupling but doesn't fix it.
- Effort: Very small
- Risk: None (no change)

## Recommended Action

## Technical Details
- Affected files: `app/views/reliever_usage/index.html.erb:68`, `app/assets/stylesheets/application.css`, possibly `app/views/adherence/index.html.erb`

## Acceptance Criteria
- [ ] Reliever usage view does not reference `adherence-*` namespaced CSS classes
- [ ] Toggle styling works correctly after rename/refactor
- [ ] Adherence page unaffected

## Work Log
- 2026-03-10: Identified by pattern-recognition-specialist in Phase 15.1 review
