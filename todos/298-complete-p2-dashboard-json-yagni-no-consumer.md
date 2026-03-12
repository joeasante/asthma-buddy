---
status: pending
priority: p2
issue_id: "298"
tags: [code-review, rails, api, yagni, dashboard]
dependencies: []
---

# Dashboard JSON API has no consumer — YAGNI violation

## Problem Statement
`DashboardController#index` was given a `format.json` response block returning `todays_best_reading`, `week_avg`, `active_illness`, `low_stock_medications`, and `preventer_adherence`. No test uses this endpoint (`test/controllers/dashboard_controller_test.rb` has zero `as: :json` calls). No JS or mobile client in the codebase consumes it. The endpoint adds maintenance surface — any field rename or query restructure must account for this undocumented JSON contract — without any current value.

## Findings
**Flagged by:** code-simplicity-reviewer

**File:** `app/controllers/dashboard_controller.rb`

The `respond_to` block (lines ~120-142) wraps the implicit HTML response and adds a JSON format returning ~8 top-level keys. Zero test coverage. Zero call sites.

## Proposed Solutions

### Option A — Remove the respond_to block (Recommended)
Revert `DashboardController#index` to an implicit HTML response. Add JSON back when a real consumer (mobile app, external API, agent tool) exists.
```ruby
# Remove respond_to block entirely
# The action will return HTML by default
```
**Pros:** Removes dead code and maintenance surface. No regression risk — nothing calls it.
**Effort:** Small (~20 lines). **Risk:** None.

### Option B — Keep and add tests
Write controller tests asserting the JSON response structure to lock in the contract.
**Pros:** If a consumer is imminent, tests document the API.
**Cons:** Speculative — still YAGNI if no real consumer.
**Effort:** Small. **Risk:** Low.

## Recommended Action

## Technical Details
- **File:** `app/controllers/dashboard_controller.rb` — `respond_to` block in `index`
- **Estimated removal:** ~20 lines

## Acceptance Criteria
- [ ] Either: `format.json` block removed from DashboardController#index, OR
- [ ] Tests added asserting the JSON response contract with at least 5 field assertions

## Work Log
- 2026-03-12: Code review finding — code-simplicity-reviewer

## Resources
- Branch: dev
