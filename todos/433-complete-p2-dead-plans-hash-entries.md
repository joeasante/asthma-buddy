---
status: pending
priority: p2
issue_id: 433
tags: [code-review, quality, billing]
dependencies: []
---

# Remove Dead Data from PLANS Hash

## Problem Statement

`config/initializers/plans.rb` contains `name`, `api_access`, and `data_export` entries that are never read anywhere in the codebase. `plan_name` hardcodes "Free"/"Premium" strings. `ApiKeyPolicy` checks `user.premium?` directly, not `plan_features[:api_access]`. There is no data export feature. This dead data misleads readers into thinking feature flags drive policy decisions.

## Findings

- **Source:** Simplicity Reviewer, Pattern Recognition
- **Location:** `config/initializers/plans.rb`, lines 3, 9-10, 13, 16-17
- **Evidence:** Grep for `api_access`, `data_export`, `PLANS.*name` returns zero hits outside the initializer itself

## Proposed Solutions

Strip PLANS to only consumed keys:

```ruby
PLANS = {
  free: {
    features: {
      symptom_log_history_days: 30,
      peak_flow_history_days: 30
    }
  },
  premium: {
    features: {
      symptom_log_history_days: nil,
      peak_flow_history_days: nil
    }
  }
}.freeze
```

- **Effort:** Small (5 minutes)
- **Risk:** None

## Acceptance Criteria

- [ ] PLANS hash contains only consumed feature keys
- [ ] All tests pass
- [ ] Billing view still renders correctly (hardcoded limit text synced)

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-15 | Created from Phase 29 code review | |
