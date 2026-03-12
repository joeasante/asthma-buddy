---
status: pending
priority: p3
issue_id: "303"
tags: [code-review, rails, api, reliever-usage, agent-native]
dependencies: []
---

# fill_pct missing from weekly_data in reliever usage JSON response

## Problem Statement
`build_weekly_data` in `RelieverUsageController` now computes a `fill_pct` value for each week (clamped bar height percentage based on GINA_URGENT_THRESHOLD). The UI chart uses this value to render bar heights. However, `reliever_usage_json` maps `weekly_data` and explicitly includes only `week_start`, `week_end`, `uses`, `band`, and `label` — omitting `fill_pct`. An API consumer or agent building a chart from the JSON endpoint would need to recompute `fill_pct` itself.

## Findings
**Flagged by:** agent-native-reviewer

**File:** `app/controllers/reliever_usage_controller.rb` — `reliever_usage_json` private method

`fill_pct` is computed in `build_weekly_data` as:
```ruby
fill_pct: [(uses / DoseLog::GINA_URGENT_THRESHOLD.to_f * 100).round, 100].min
```

But the JSON serialization at line ~143-145 omits it from the `weekly_data` map.

## Proposed Solutions
### Option A — Add fill_pct to the weekly_data map
```ruby
weekly_data: @weekly_data.map { |w|
  { week_start: w[:week_start], week_end: w[:week_end],
    uses: w[:uses], band: w[:band], label: w[:label], fill_pct: w[:fill_pct] }
}
```
**Effort:** Trivial.

## Recommended Action

## Technical Details
- **File:** `app/controllers/reliever_usage_controller.rb` — `reliever_usage_json`

## Acceptance Criteria
- [ ] `weekly_data` in reliever usage JSON includes `fill_pct` key (integer 0-100)

## Work Log
- 2026-03-12: Code review finding — agent-native-reviewer

## Resources
- Branch: dev
