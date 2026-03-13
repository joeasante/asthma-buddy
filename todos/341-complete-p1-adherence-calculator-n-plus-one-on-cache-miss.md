---
status: pending
priority: p1
issue_id: "341"
tags: [code-review, performance, caching, rails, n-plus-one]
dependencies: []
---

# AdherenceCalculator called without preloaded_logs — N+1 queries on every dashboard cache miss

## Problem Statement

`DashboardVariables#set_dashboard_vars` calls `AdherenceCalculator.call(m, today)` inside the preventer_adherence fetch block without passing `preloaded_logs:`. Although the preventer query uses `.includes(:dose_logs)`, `AdherenceCalculator` is unaware — it falls into the `else` branch at line 24 and fires a fresh `WHERE recorded_at ... COUNT` SQL query per medication.

For a user with 5 preventer medications, every dashboard cache miss triggers 5 extra COUNT queries, even though the dose_logs are already in memory.

## Findings

- `app/controllers/concerns/dashboard_variables.rb:35` — `AdherenceCalculator.call(m, today)` called without `preloaded_logs:`
- `app/services/adherence_calculator.rb:21-26` — without `preloaded_logs:`, the calculator runs `@medication.dose_logs.where(recorded_at: ...).count`
- The `preloaded_logs:` keyword argument exists precisely for this use case (the comment on line 6 says "Pass preloaded_logs (array) to skip the per-day SQL query when batch-loading")
- `.includes(:dose_logs)` on line 32 already loads all dose_logs into memory — the preloaded data is being discarded

## Proposed Solutions

### Option A: Pass today-filtered preloaded_logs (Recommended)
```ruby
.map do |m|
  today_logs = m.dose_logs.select { |dl| dl.recorded_at.to_date == today }
  result = AdherenceCalculator.call(m, today, preloaded_logs: today_logs)
  { ..., taken: result.taken, ... }
end
```
- **Pros:** Zero extra queries; uses existing preloaded data exactly as designed
- **Cons:** None
- **Effort:** Small
- **Risk:** Low

### Option B: Pass all dose_logs and let calculator filter
Change AdherenceCalculator to accept a full dose_logs array and filter internally.
- **Pros:** Caller doesn't need to know the date filter
- **Cons:** More work inside the calculator; current API already handles this correctly
- **Effort:** Medium
- **Risk:** Low

## Recommended Action

Option A. One-line fix at the call site.

## Technical Details

**Affected files:**
- `app/controllers/concerns/dashboard_variables.rb` — fix call site
- `test/controllers/dashboard_controller_test.rb` — consider adding a query count assertion

## Acceptance Criteria

- [ ] `AdherenceCalculator.call` receives `preloaded_logs:` in `set_dashboard_vars`
- [ ] No SQL queries fired for `dose_logs` inside the cache fetch block (verify with query logging or bullet gem)
- [ ] All 519 tests pass

## Work Log

- 2026-03-13: Identified in Phase 22 code review (performance-oracle)
