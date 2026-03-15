---
status: pending
priority: p2
issue_id: 447
tags: [code-review, billing, jobs, reliability]
dependencies: []
---

# Add Deduplication Guard to TrialReminderJob

## Problem Statement

Unlike `MissedDoseCheckJob` which checks for duplicate notifications before creating them, `TrialReminderJob` has no idempotency mechanism. If the job runs twice (manual trigger, catch-up after downtime, queue hiccup), users receive duplicate trial-ending-soon emails. The job also has no failure recovery — if it fails to run on a given day, those users never get the reminder.

## Proposed Solutions

### Solution A: Track reminder sent timestamp (Recommended)
Add `trial_reminder_sent_at` to users table. Check before sending:
```ruby
next if user.trial_reminder_sent_at.present?
BillingMailer.trial_ending_soon(user).deliver_later
user.update_column(:trial_reminder_sent_at, Time.current)
```

### Solution B: Use cache-based deduplication
```ruby
cache_key = "trial_reminder:#{user.id}"
next if Rails.cache.exist?(cache_key)
BillingMailer.trial_ending_soon(user).deliver_later
Rails.cache.write(cache_key, true, expires_in: 7.days)
```

- **Effort**: Small-Medium
- **Risk**: Low

## Acceptance Criteria

- [ ] Running job twice in same day does not send duplicate emails
- [ ] Users whose trial ends in 3 days still receive exactly one email
