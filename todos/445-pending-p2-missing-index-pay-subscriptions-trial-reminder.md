---
status: pending
priority: p2
issue_id: 445
tags: [code-review, performance, billing, database]
dependencies: []
---

# Add Missing Index on pay_subscriptions(status, trial_ends_at)

## Problem Statement

`TrialReminderJob` queries `Pay::Subscription.where(status: "trialing").where(trial_ends_at: range)` daily. The `pay_subscriptions` table has no index on `status` or `trial_ends_at`, causing a full table scan. Negligible now but becomes a bottleneck at 10,000+ subscriptions on SQLite.

## Proposed Solution

```ruby
# db/migrate/xxx_add_index_to_pay_subscriptions_status_trial_ends_at.rb
add_index :pay_subscriptions, [:status, :trial_ends_at],
          name: "index_pay_subscriptions_on_status_and_trial_ends_at"
```

- **Effort**: Small (one migration)
- **Risk**: None

## Acceptance Criteria

- [ ] Composite index exists on `pay_subscriptions(status, trial_ends_at)`
- [ ] Migration passes
- [ ] TrialReminderJob query uses the index (EXPLAIN)
