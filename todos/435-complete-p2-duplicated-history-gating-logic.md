---
status: pending
priority: p2
issue_id: 435
tags: [code-review, quality, architecture, billing]
dependencies: []
---

# Extract Duplicated History-Gating Logic

## Problem Statement

The history cutoff calculation is copy-pasted across `symptom_logs_controller.rb` and `peak_flow_readings_controller.rb`:

```ruby
cutoff = Current.user.history_cutoff_date(:feature_key)
@history_limited = cutoff.present?
effective_start = [@start_date, cutoff&.to_date].compact.max
```

Identical pattern except for the feature key.

## Findings

- **Source:** Architecture Strategist, Simplicity Reviewer
- **Location:** `app/controllers/symptom_logs_controller.rb` and `app/controllers/peak_flow_readings_controller.rb`

## Proposed Solutions

Extract a shared method into a concern or `ApplicationController`:

```ruby
def apply_plan_limit(feature_key, start_date)
  cutoff = Current.user.history_cutoff_date(feature_key)
  [cutoff.present?, [start_date, cutoff&.to_date].compact.max]
end
```

- **Effort:** Small (10 minutes)
- **Risk:** Low

## Acceptance Criteria

- [ ] No duplicated cutoff logic across controllers
- [ ] History limiting works identically for both resources
- [ ] All tests pass

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-15 | Created from Phase 29 code review | |
