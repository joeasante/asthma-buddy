---
status: pending
priority: p3
issue_id: "181"
tags: [code-review, css, naming, peak-flow]
dependencies: []
---

# filter-chip-dot Classes Lack pf- Namespace Prefix

## Problem Statement
peak_flow.css defines `.filter-chip-dot` and `.filter-chip-dot--green/yellow/red` (lines 424-433). All other peak-flow-specific filter classes use the `pf-` prefix (`.pf-filter-chip`, `.pf-filter-group`, etc.). `.filter-chip-dot` is inconsistently named and could collide with future shared filter chip components. _filter_bar.html.erb uses `class="filter-chip-dot filter-chip-dot--<%= value %>"`.

## Proposed Solutions

### Option A
Rename to `pf-filter-chip-dot` and `pf-filter-chip-dot--*` in both the CSS and the template.
- Effort: Small
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: app/assets/stylesheets/peak_flow.css (lines 424-433), app/views/peak_flow_readings/_filter_bar.html.erb (line 33)

## Acceptance Criteria
- [ ] `.pf-filter-chip-dot` and `.pf-filter-chip-dot--green/yellow/red` defined in peak_flow.css
- [ ] `_filter_bar.html.erb` references the renamed classes
- [ ] No remaining references to the unprefixed `.filter-chip-dot` class in the codebase

## Work Log
- 2026-03-10: Created via code review
