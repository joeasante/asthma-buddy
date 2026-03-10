---
status: complete
priority: p2
issue_id: "194"
tags: [code-review, rails, maintainability, phase-15-1]
dependencies: []
---

# GINA Review Threshold Hardcoded Independently in `gina_band` and `build_correlation`

## Problem Statement
The GINA review threshold of 3 uses/week is defined twice: once in `gina_band` (line 86: `elsif uses >= 3`) and once in `build_correlation` (line 98-99: `w[:uses] >= 3` and `w[:uses] <= 2`). When a clinician asks to change the threshold, it must be updated in two separate places and they can silently drift.

## Findings
- **File:** `app/controllers/reliever_usage_controller.rb:86,98-99`
- `gina_band` threshold: `uses >= 3` → `:review`
- `build_correlation` threshold: `w[:uses] >= 3` for high-use weeks
- These encode the same clinical boundary independently
- Rails reviewer and architecture reviewer both flagged

## Proposed Solutions

### Option A (Recommended): Extract constant
```ruby
GINA_REVIEW_THRESHOLD = 3
GINA_URGENT_THRESHOLD = 6

def gina_band(uses)
  if uses >= GINA_URGENT_THRESHOLD
    :urgent
  elsif uses >= GINA_REVIEW_THRESHOLD
    :review
  else
    :controlled
  end
end

# build_correlation
high_use_weeks = weekly_data.select { |w| w[:uses] >= GINA_REVIEW_THRESHOLD }
low_use_weeks  = weekly_data.select { |w| w[:uses] < GINA_REVIEW_THRESHOLD }
```
- Effort: Small
- Risk: None

### Option B: Move constants to a service object (if RelieverUsageClassifier is extracted per todo 198)
All thresholds live in `MONTHLY_CONTROL_TIERS` and `GINA_*` constants in one service. Controller just delegates.
- Effort: Medium (depends on architecture refactor)
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: `app/controllers/reliever_usage_controller.rb:86,98-99`

## Acceptance Criteria
- [ ] Single constant defines the 3-uses/week GINA review boundary
- [ ] Both `gina_band` and `build_correlation` reference the same constant
- [ ] All tests pass (no behaviour change)

## Work Log
- 2026-03-10: Identified by kieran-rails-reviewer in Phase 15.1 review
