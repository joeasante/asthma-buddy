---
status: pending
priority: p2
issue_id: "294"
tags: [code-review, rails, performance, n-plus-one, settings]
dependencies: []
---

# set_header_eyebrow_vars loads all dose_logs into memory — grows unbounded

## Problem Statement
`Settings::BaseController#set_header_eyebrow_vars` calls `Current.user.medications.chronological.includes(:dose_logs)`, which loads every dose log ever recorded for every medication into Ruby memory. It then calls `low_stock?` on each medication, which calls `remaining_doses`, which calls `dose_logs.sum(:puffs)` — but because dose_logs is already loaded, this runs in Ruby as `array.sum`. A user with 5 medications and 3 years of twice-daily logs has ~10,950 DoseLog rows pulled into Ruby on every medication mutation (create, update, destroy, refill, and dose log create/destroy).

## Findings
**Flagged by:** performance-oracle

**File:** `app/controllers/settings/base_controller.rb`

```ruby
def set_header_eyebrow_vars
  all_meds = Current.user.medications.chronological.includes(:dose_logs)
  visible  = all_meds.reject { |m| m.course? && !m.course_active? }
  @header_medication_count = visible.size
  @header_low_stock_count  = visible.count(&:low_stock?)
end
```

`low_stock?` only needs the total puff sum per medication — not individual log rows. The `includes` is over-fetching for what is ultimately an integer comparison.

## Proposed Solutions

### Option A — Use LEFT JOIN + GROUP + SUM (Recommended)
Replace the includes approach with a single aggregate query:
```ruby
def set_header_eyebrow_vars
  meds = Current.user.medications
    .select("medications.*, COALESCE(SUM(dose_logs.puffs), 0) AS total_puffs_logged")
    .left_joins(:dose_logs)
    .group("medications.id")
    .chronological
  visible = meds.reject { |m| m.course? && !m.course_active? }
  @header_medication_count = visible.size
  @header_low_stock_count  = visible.count { |m| m.low_stock_for_count?(m.total_puffs_logged) }
end
```
Requires a new `low_stock_for_count?` method on Medication that accepts a pre-computed sum.
**Pros:** One query, O(medications) not O(dose_logs). Scales with user tenure.
**Cons:** Requires model method addition. Medium effort.
**Effort:** Medium. **Risk:** Low.

### Option B — Keep includes, add a comment noting the scale risk
Document the scalability concern and accept it as a known trade-off until user data volumes warrant optimization.
**Effort:** Trivial. **Risk:** None now, deferred risk later.

## Recommended Action

## Technical Details
- **File:** `app/controllers/settings/base_controller.rb` — `set_header_eyebrow_vars`
- **Called from:** `Settings::MedicationsController` (create, update, destroy, refill) and `Settings::DoseLogsController` (create, destroy)
- **At 10 medications × 730 logs/year × 3 years:** ~21,900 DoseLog rows per request

## Acceptance Criteria
- [ ] `set_header_eyebrow_vars` does not load unbounded dose log rows into Ruby
- [ ] The replacement query returns correct low_stock counts matching existing behaviour
- [ ] No regression in `@header_medication_count` or `@header_low_stock_count` values in tests

## Work Log
- 2026-03-12: Code review finding — performance-oracle

## Resources
- Branch: dev
- Related: 275-pending-p2-set-header-eyebrow-vars-duplicated.md
