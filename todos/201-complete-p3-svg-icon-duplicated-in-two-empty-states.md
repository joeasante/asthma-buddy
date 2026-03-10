---
status: complete
priority: p3
issue_id: "201"
tags: [code-review, rails, dry, frontend, phase-15-1]
dependencies: []
---

# Inhaler SVG Icon Duplicated Verbatim in Two Empty States

## Problem Statement
The inhaler SVG path (`M9 2h6...`) appears identically in 3 places in `reliever_usage/index.html.erb`: the page header icon (24×24), and both empty state icons (48×48). Changes to the icon shape require updating 3 locations.

## Findings
- **File:** `app/views/reliever_usage/index.html.erb:14-19, 33-38, 51-56`
- Same SVG path, different `width`/`height`/`stroke-width` attributes
- Rails reviewer and simplicity reviewer both flagged; simplicity estimated ~22 LOC saved

## Proposed Solutions

### Option A (Recommended): Extract to partial with size locals
```erb
<%# app/views/reliever_usage/_reliever_icon.html.erb %>
<svg width="<%= size %>" height="<%= size %>" viewBox="0 0 24 24" fill="none"
     stroke="currentColor" stroke-width="<%= stroke_width %>"
     stroke-linecap="round" stroke-linejoin="round">
  <path d="M9 2h6l1 4H8L9 2z"/>
  <rect x="7" y="6" width="10" height="14" rx="2"/>
  <line x1="12" y1="10" x2="12" y2="16"/>
  <line x1="9" y1="13" x2="15" y2="13"/>
</svg>
```
Call: `<%= render "reliever_usage/reliever_icon", size: 24, stroke_width: 2 %>`
- Effort: Small
- Risk: None

## Recommended Action

## Technical Details
- Affected files: `app/views/reliever_usage/index.html.erb`, new `_reliever_icon.html.erb`

## Acceptance Criteria
- [ ] SVG path defined once in a partial
- [ ] Three call sites use the partial with appropriate size/stroke_width locals
- [ ] Visual output unchanged

## Work Log
- 2026-03-10: Identified by kieran-rails-reviewer and code-simplicity-reviewer in Phase 15.1 review
