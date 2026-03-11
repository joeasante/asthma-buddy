---
status: complete
priority: p2
issue_id: "214"
tags: [code-review, agent-native, api, json, reliever-usage]
dependencies: []
---

# `reliever_usage_json` Has Ambiguous Field Names and Missing Monthly Window Boundary

## Problem Statement

Two semantic issues in the JSON response from `GET /reliever-usage.json` that make it harder for agents to correctly interpret the data:

1. **`high_avg` / `low_avg` are ambiguous** — without the surrounding HTML prose, an agent cannot tell which direction indicates clinical deterioration. `high_avg: 320` being *lower* than `low_avg: 410` (peak flow goes *down* when reliever use goes *up*) is not self-evident from the field names.

2. **`monthly_uses` has no boundary dates** — the weekly bars use ISO Monday-aligned windows, but `monthly_uses` counts from `beginning_of_month` (a different boundary). An agent correlating these two fields will compute incorrect totals. There are no fields indicating what date range `monthly_uses` covers.

## Findings

**Flagged by:** agent-native-reviewer (P2-B, P2-C)

**Location:** `app/controllers/reliever_usage_controller.rb` lines 148–164 (`reliever_usage_json`)

```ruby
{
  monthly_uses:   @monthly_uses,      # from 2026-03-01, different boundary than weekly_data
  monthly_status: @monthly_pill_label,
  correlation:    @correlation,        # { high_avg: 310, low_avg: 430 } — unclear direction
}
```

## Proposed Solutions

### Option A — Rename correlation keys + add monthly window (Recommended)
**Effort:** Small | **Risk:** Low (no existing JSON consumers)

```ruby
{
  weeks:       @weeks,
  weekly_data: ...,
  monthly_uses:   @monthly_uses,
  monthly_status: @monthly_pill_label,
  monthly_window: {
    start: Date.current.beginning_of_month.iso8601,
    end:   Date.current.iso8601
  },
  correlation: @correlation ? {
    high_use_week_avg_peak_flow: @correlation[:high_avg],
    low_use_week_avg_peak_flow:  @correlation[:low_avg],
    threshold_uses: DoseLog::GINA_REVIEW_THRESHOLD
  } : nil,
  gina_bands: { ... }
}
```

**Pros:** Self-documenting. Agent can reason about correlation direction and monthly boundary without guessing.
**Cons:** Slightly larger response payload.

### Option B — Add `correlation_context` explanatory field only
**Effort:** Trivial | **Risk:** None

```ruby
correlation: @correlation&.merge(
  interpretation: "lower peak flow during high-use weeks indicates worse control"
)
```

Adds context without renaming keys (backward compatibility).

### Option C — Document in a code comment only
**Effort:** Trivial | **Risk:** None (no API impact)

Not sufficient for agent consumption — comments aren't in the response.

## Recommended Action

Option A. No existing JSON consumers means renaming keys is zero-risk. The `monthly_window` dates cost one line and eliminate a genuine reasoning hazard.

## Technical Details

- **Affected files:** `app/controllers/reliever_usage_controller.rb` (lines 148–164)
- **Also update:** `test/controllers/reliever_usage_controller_test.rb` JSON test to assert `monthly_window` presence and correlation field names

## Acceptance Criteria

- [ ] Correlation fields renamed to `high_use_week_avg_peak_flow` / `low_use_week_avg_peak_flow`
- [ ] `correlation` object includes `threshold_uses` field
- [ ] `monthly_window` object with `start`/`end` dates present in JSON response
- [ ] JSON test updated to assert the new field names

## Work Log

- 2026-03-10: Identified by agent-native-reviewer. No existing consumers — renaming is safe.
