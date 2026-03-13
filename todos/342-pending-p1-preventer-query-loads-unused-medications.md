---
status: pending
priority: p1
issue_id: "342"
tags: [code-review, performance, caching, rails, sql]
dependencies: []
---

# Ruby-side doses_per_day filter loads unused medications and their dose_logs

## Problem Statement

In `DashboardVariables#set_dashboard_vars`, the preventer_adherence query uses `.includes(:dose_logs)` before a Ruby-side `.select { |m| m.doses_per_day.present? }` filter. This loads every preventer medication (including those with no daily schedule) and ALL their associated dose_logs into memory, then discards the ones with nil `doses_per_day`.

If a user has 3 preventer medications but only 1 has a daily schedule, the query loads 3 medications + all their dose_logs but only uses 1 medication's data. The dose_logs for the 2 discarded medications are loaded and thrown away.

## Findings

- `app/controllers/concerns/dashboard_variables.rb:32-33` — `.includes(:dose_logs).select { |m| m.doses_per_day.present? }` — filter happens in Ruby after loading everything from DB
- The fix is to push the filter to SQL: `.where.not(doses_per_day: nil).includes(:dose_logs)`

## Proposed Solutions

### Option A: Push filter to SQL (Recommended)
```ruby
user.medications
  .where(medication_type: :preventer, course: false)
  .where.not(doses_per_day: nil)
  .includes(:dose_logs)
  .select { |m| m.doses_per_day.present? }  # can remove after SQL filter
  .map do |m| ...
```
Actually can remove the Ruby `.select` entirely once the SQL filter is in place.
- **Pros:** Fewer rows loaded, fewer dose_logs fetched, smaller memory footprint
- **Cons:** None
- **Effort:** Small
- **Risk:** Low

### Option B: Accept current state
The cache masks the extra load — it only happens on cache miss every 5 minutes.
- **Pros:** No code change
- **Cons:** Wasteful on cache miss; loads data that is never used
- **Effort:** None
- **Risk:** Low

## Recommended Action

Option A. One-line change. Should be paired with todo 341 fix.

## Technical Details

**Affected files:**
- `app/controllers/concerns/dashboard_variables.rb`

## Acceptance Criteria

- [ ] `.where.not(doses_per_day: nil)` added before `.includes(:dose_logs)` in preventer query
- [ ] Ruby-side `.select { |m| m.doses_per_day.present? }` removed (redundant after SQL filter)
- [ ] Existing 519 tests pass

## Work Log

- 2026-03-13: Identified in Phase 22 code review (performance-oracle)
