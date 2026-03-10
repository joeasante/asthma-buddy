---
status: complete
priority: p1
issue_id: "189"
tags: [code-review, performance, rails, phase-15-1]
dependencies: []
---

# `setup_monthly_stats` Re-Queries Medications on Every Call Path Including Empty States

## Problem Statement
`setup_monthly_stats` (controller line 49) builds its dose_logs query using `Current.user.medications.where(medication_type: :reliever)` as a subquery argument. However, `@relievers` — the identical scoped relation — is already computed at line 10–12 of `index`. The method ignores `@relievers` entirely and re-derives it from scratch. This fires an extra medications query on every request.

More critically, on the `@relievers.empty?` early-return path, `setup_monthly_stats` is called even though `@relievers` was just found empty — causing a redundant `SELECT` on `medications` that will always return zero results.

## Findings
- **File:** `app/controllers/reliever_usage_controller.rb:47-55`
- `setup_monthly_stats` is called in 3 code paths (lines 17, 30, 42)
- Line 50: `Current.user.medications.where(medication_type: :reliever)` — re-derived, ignores `@relievers`
- On the empty-reliever path: a second medications query fires even though the answer is already known (zero)
- Performance agent rated this P1; Rails reviewer rated P1; architecture reviewer rated P2

## Proposed Solutions

### Option A (Recommended): Pass `@relievers` as parameter
```ruby
def setup_monthly_stats(relievers = @relievers)
  if relievers.empty?
    @monthly_uses = 0
  else
    month_start = Date.current.beginning_of_month
    @monthly_uses = Current.user.dose_logs
      .where(medication: relievers)
      .where(recorded_at: month_start.beginning_of_day..)
      .count
  end
  @monthly_pill_class = monthly_pill_class(@monthly_uses)
  @monthly_pill_label = monthly_pill_label(@monthly_uses)
end
```
- Effort: Small
- Risk: None — reuses already-loaded relation; result is identical

### Option B: Set defaults at top of action, inline the empty-reliever guard
Instead of calling `setup_monthly_stats` on the empty-reliever path, assign `@monthly_uses = 0` directly and skip the DB call entirely for that branch.
- Effort: Small
- Risk: None

## Recommended Action

## Technical Details
- Affected files: `app/controllers/reliever_usage_controller.rb` lines 14-19, 47-55

## Acceptance Criteria
- [ ] `setup_monthly_stats` uses `@relievers` (or a passed-in parameter) instead of re-querying
- [ ] No medications SELECT fires when `@relievers` is empty
- [ ] Rails log shows no redundant queries on empty-state page load
- [ ] All tests pass

## Work Log
- 2026-03-10: Identified by performance-oracle (P1) and kieran-rails-reviewer in Phase 15.1 review
