---
status: pending
priority: p2
issue_id: 446
tags: [code-review, code-quality, billing, simplification]
dependencies: []
---

# Strip Dead Data from PLANS Constant

## Problem Statement

8 key-value pairs in `config/initializers/plans.rb` are never read at runtime: `name` (both tiers), `amount` and `currency` (both pricing tiers), `api_access` and `health_report_export` (both tiers). These create a false impression of data-driven feature gating when all feature checks use `premium?` directly. Prior todo #433 flagged this but 29-04 added more dead entries.

## Proposed Solution

Slim PLANS to only consumed keys:
```ruby
PLANS = {
  free: {
    features: {
      symptom_log_history_days: 30,
      peak_flow_history_days: 30
    }
  },
  premium: {
    trial_days: 30,
    pricing: {
      monthly: { display: "$7.99/month" },
      annual: { display: "$59.99/year", savings: "37%" }
    },
    features: {
      symptom_log_history_days: nil,
      peak_flow_history_days: nil
    }
  }
}.freeze
```

- **Effort**: Small
- **Risk**: Low — verify no code references removed keys

## Acceptance Criteria

- [ ] Only consumed keys remain in PLANS
- [ ] All tests pass
- [ ] `plan_name` method still works (hardcodes strings, doesn't read PLANS)
