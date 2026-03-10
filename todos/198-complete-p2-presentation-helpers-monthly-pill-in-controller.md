---
status: complete
priority: p2
issue_id: "198"
tags: [code-review, rails, architecture, phase-15-1]
dependencies: []
---

# `monthly_pill_class` and `monthly_pill_label` Presentation Helpers Belong Outside Controller

## Problem Statement
`monthly_pill_class` and `monthly_pill_label` (controller lines 122–140) are pure data-to-string mappings with no dependency on controller state. They embed CSS class names (`"eyebrow-pill--green"`) and display labels in a controller, violating the separation of concerns. CSS class names in controllers make design system refactors harder to find. These methods should live in a view helper or a domain service.

## Findings
- **File:** `app/controllers/reliever_usage_controller.rb:122-140`
- `monthly_pill_class(uses)` → CSS string — presentation concern
- `monthly_pill_label(uses)` → display label — also presentation
- Both use thresholds 8 and 15 — duplicated decision tree structure
- Simplicity reviewer identified a table-driven refactor saving ~14 lines
- Architecture reviewer and Rails reviewer both flagged

## Proposed Solutions

### Option A (Recommended): Move to `RelieverUsageHelper`, merge into tier lookup
```ruby
# app/helpers/reliever_usage_helper.rb
module RelieverUsageHelper
  MONTHLY_CONTROL_TIERS = [
    { max: 8,             css: "eyebrow-pill--green", label: "Well controlled"    },
    { max: 15,            css: "eyebrow-pill--amber", label: "Review recommended" },
    { max: Float::INFINITY, css: "eyebrow-pill--red",  label: "Speak to your GP"  }
  ].freeze

  def monthly_control_tier(uses)
    MONTHLY_CONTROL_TIERS.find { |t| uses <= t[:max] }
  end
end
```
Controller calls:
```ruby
tier = monthly_control_tier(@monthly_uses)
@monthly_pill_class = tier[:css]
@monthly_pill_label = tier[:label]
```
- Effort: Small
- Risk: None

### Option B: Keep in controller but merge into single method
Combine the two parallel if/elsif chains into one lookup (same TIERS table above) but leave it in the controller private section. Better than current but still not in the right layer.
- Effort: Very small
- Risk: None

## Recommended Action

## Technical Details
- Affected files: `app/controllers/reliever_usage_controller.rb:122-140`, `app/helpers/reliever_usage_helper.rb` (new)

## Acceptance Criteria
- [ ] No CSS class strings in the controller
- [ ] Thresholds 8 and 15 defined in one place
- [ ] `monthly_pill_class` and `monthly_pill_label` methods removed from controller
- [ ] All tests pass

## Work Log
- 2026-03-10: Identified by architecture-strategist, kieran-rails-reviewer, and code-simplicity-reviewer in Phase 15.1 review
