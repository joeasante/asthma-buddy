---
status: complete
priority: p3
issue_id: "202"
tags: [code-review, rails, clarity, phase-15-1]
dependencies: []
---

# `max_scale = 6.0` Magic Number in View — Clinical Meaning Undocumented

## Problem Statement
`max_scale = 6.0` in `reliever_usage/index.html.erb` (line 93) is the GINA "urgent" threshold — any week with 6+ uses fills the bar to 100%. This clinical constant is defined anonymously in the view with no comment and also appears independently in `gina_band` (controller line 86: `if uses >= 6`). The two occurrences will silently drift if the threshold is changed.

## Findings
- **File:** `app/views/reliever_usage/index.html.erb:93`
- `<% max_scale = 6.0 %>` — no comment explaining clinical basis
- Also appears at `controller:86` as the `:urgent` threshold
- Rails reviewer, simplicity reviewer, and architecture reviewer all flagged

## Proposed Solutions

### Option A (Recommended): Move to controller as instance variable
```ruby
# controller
@bar_max_scale = GINA_URGENT_THRESHOLD.to_f  # set alongside GINA_URGENT_THRESHOLD = 6 constant
```
```erb
<%# view %>
<% fill_pct = [(@weekly_data... / @bar_max_scale * 100).round, 100].min %>
```
- Effort: Very small
- Risk: None

### Option B: Add comment in view
```erb
<% max_scale = 6.0 # GINA urgent threshold — bars cap at 100% at 6+ uses/week %>
```
Leaves the magic number but explains it. Doesn't address the duplication.
- Effort: Minimal
- Risk: None

## Recommended Action

## Technical Details
- Affected files: `app/views/reliever_usage/index.html.erb:93`, `app/controllers/reliever_usage_controller.rb:86`

## Acceptance Criteria
- [ ] `6.0` defined once with a comment or constant name explaining GINA basis
- [ ] View references controller-provided value or named constant

## Work Log
- 2026-03-10: Identified by kieran-rails-reviewer and code-simplicity-reviewer in Phase 15.1 review
