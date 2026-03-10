---
status: pending
priority: p2
issue_id: "211"
tags: [code-review, rails, bug, reliever-usage, weekly-data]
dependencies: []
---

# `build_weekly_data` Monday-Alignment Can Produce 13 Bars on a 12-Week Selection

## Problem Statement

When `@weeks = 12`, `period_start` is 84 days ago. The Monday-alignment step subtracts up to 6 additional days (if `period_start` falls on a Sunday). So `current` can start up to 90 days in the past. The loop terminates when `current > Date.current`, which means it may produce 13 weekly bars for a "12 weeks" selection. There is no test that asserts `@weekly_data.size <= 12`.

## Findings

**Flagged by:** kieran-rails-reviewer (P2)

**Location:** `app/controllers/reliever_usage_controller.rb` lines 82–108

```ruby
def build_weekly_data(logs, period_start)
  by_date = logs.group_by { |l| l.recorded_at.to_date }
  days_since_monday = (period_start.wday - 1) % 7
  current = period_start - days_since_monday   # can go back up to 6 extra days

  weeks = []
  while current <= Date.current                # no upper limit on week count
    # ...
    current += 7
  end
  weeks
end
```

For `@weeks = 12` with `period_start` on a Sunday, `current` starts 90 days ago, and `Date.current - 90 days + 13 * 7 = Date.current + 1` — so 13 iterations complete before the loop exits.

**User-facing impact:** 13 bars render in the "12 weeks" chart instead of 12. The first bar represents a partial week (Monday-aligned but earlier than the nominal 12-week boundary).

## Proposed Solutions

### Option A — Clamp output to `@weeks` bars after building (Recommended)
**Effort:** Small | **Risk:** Low

```ruby
weeks.last(@weeks)
```

Add after the `while` loop. Keeps Monday-alignment logic intact (which ensures full 7-day windows and consistent GINA thresholds) and simply drops any extra leading partial-week bar.

### Option B — Cap the loop to `@weeks` iterations
**Effort:** Small | **Risk:** Low

```ruby
while current <= Date.current && weeks.size < @weeks
```

Stops after exactly `@weeks` iterations. May omit the most recent partial week if it causes the count to exceed `@weeks`.

### Option C — Accept the extra bar
**Effort:** None | **Risk:** Low — one extra bar is minor UX issue

The extra bar represents real data (it shows actual usage for a partial pre-period week). The chart has `overflow-x: auto` so it doesn't break the layout.

## Recommended Action

Option A — `weeks.last(@weeks)`. Simple, predictable, and ensures the chart always shows exactly what the user selected. Add a test: `assert_equal 12, @weekly_data.size` for `weeks: 12`.

## Technical Details

- **Affected files:** `app/controllers/reliever_usage_controller.rb`, `test/controllers/reliever_usage_controller_test.rb`
- **Test to add:** `test "index produces exactly N weekly bars for each period setting"`

## Acceptance Criteria

- [ ] `GET /reliever-usage?weeks=8` always returns exactly 8 bars in `@weekly_data`
- [ ] `GET /reliever-usage?weeks=12` always returns exactly 12 bars
- [ ] Test asserts bar count for both `weeks: 8` and `weeks: 12`
- [ ] All 367 tests still pass

## Work Log

- 2026-03-10: Identified by kieran-rails-reviewer. No current test covers bar count.
