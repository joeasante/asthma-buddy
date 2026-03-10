---
status: complete
priority: p1
issue_id: "188"
tags: [code-review, performance, rails, phase-15-1]
dependencies: []
---

# Double Query: `all_logs.any?` Fires COUNT, then `all_logs.to_a` Fires SELECT

## Problem Statement
`RelieverUsageController#index` calls `all_logs.any?` (line 25) followed by `all_logs.to_a` (line 34) on the same unloaded ActiveRecord relation. Because `all_logs` is a scope and not yet materialised, `any?` fires `SELECT 1 ... LIMIT 1` (a COUNT-equivalent), and then `to_a` fires `SELECT *`. This is two round-trips to SQLite for a dataset that is fetched immediately afterward. It is wasteful and correctable with a one-line change.

## Findings
- **File:** `app/controllers/reliever_usage_controller.rb:25,34`
- Rails `.any?` on an unloaded relation = `SELECT 1 WHERE ... LIMIT 1`
- Rails `.to_a` on the same relation = `SELECT * WHERE ...`
- Loading `.to_a` once and calling `.any?` on the Ruby array eliminates the COUNT query
- Performance agent confirmed: one round-trip saved per page load on the happy path

## Proposed Solutions

### Option A (Recommended): Load once, check array
```ruby
loaded_logs = Current.user.dose_logs
  .where(medication: @relievers)
  .where(recorded_at: date_range.first.beginning_of_day..date_range.last.end_of_day)
  .to_a

@has_logs = loaded_logs.any?

unless @has_logs
  @weekly_data = []
  @correlation = nil
  setup_monthly_stats
  return
end

@weekly_data = build_weekly_data(loaded_logs, period_start)
```
- Effort: Small
- Risk: None (behaviour unchanged)

### Option B: Combine with early-return collapse (see todo 189)
Collapse both early-return paths into a single guard: `@relievers.empty? || logs.empty?`. Eliminates `@has_logs` ivar entirely and keeps the view cleaner.
- Effort: Small
- Risk: None

## Recommended Action

## Technical Details
- Affected files: `app/controllers/reliever_usage_controller.rb` lines 21–34

## Acceptance Criteria
- [ ] `all_logs.any?` removed; replaced with `.any?` on an already-loaded Ruby array
- [ ] `@weekly_data = build_weekly_data(...)` receives the pre-loaded array
- [ ] Rails log shows one SELECT (not COUNT then SELECT) for dose logs on a request with data
- [ ] All tests pass

## Work Log
- 2026-03-10: Identified by performance-oracle and kieran-rails-reviewer agents in Phase 15.1 review
