---
status: pending
priority: p2
issue_id: "068"
tags: [code-review, security, rails]
dependencies: []
---

# No Rate Limiting on Health Data Write Endpoints

## Problem Statement

Auth-sensitive endpoints (`sessions#create`, `registrations#create`, `passwords#create`) all have `rate_limit` applied. Health data write endpoints (`peak_flow_readings#create`, `settings#update_personal_best`) do not. An authenticated attacker with a valid session token could flood the database with thousands of readings or personal best records per minute, causing SQLite lock contention and storage exhaustion.

## Findings

**Flagged by:** security-sentinel

**What has rate limiting:**
```ruby
# sessions_controller.rb
rate_limit to: 10, within: 3.minutes, only: :create
# registrations_controller.rb
rate_limit to: 10, within: 3.minutes, only: :create
# passwords_controller.rb
rate_limit to: 10, within: 3.minutes, only: :create
```

**What does not:**
```ruby
# peak_flow_readings_controller.rb — no rate_limit
# settings_controller.rb — no rate_limit
```

Note: `SymptomLogsController` also lacks rate limiting, so this is consistent with the existing authenticated-resource pattern — but it is still a gap worth closing as the app approaches production.

## Proposed Solutions

### Option A: Add rate_limit to both controllers (Recommended)

```ruby
# peak_flow_readings_controller.rb
class PeakFlowReadingsController < ApplicationController
  rate_limit to: 60, within: 1.minute, only: :create
```

```ruby
# settings_controller.rb
class SettingsController < ApplicationController
  rate_limit to: 10, within: 1.minute, only: :update_personal_best
```

Peak flow: 60/min allows a reading every second (far above clinical frequency). Personal best: 10/min (set at most a few times per clinic visit).

**Pros:** Consistent with app's rate-limiting pattern; prevents database abuse
**Cons:** None meaningful
**Effort:** XSmall
**Risk:** Zero

### Option B: Apply a blanket rate limit at ApplicationController level for all authenticated write actions

Use a `before_action` concern or global `rate_limit` with conditions.

**Pros:** Covers all current and future write actions automatically
**Cons:** May be too broad; different actions have different appropriate thresholds
**Effort:** Medium
**Risk:** Low-Medium

## Recommended Action

Option A — targeted, explicit, follows existing pattern.

Also add rate limiting to `SymptomLogsController#create` in the same pass (consistency).

## Technical Details

**Affected files:**
- `app/controllers/peak_flow_readings_controller.rb`
- `app/controllers/settings_controller.rb`
- `app/controllers/symptom_logs_controller.rb` (while here)

## Acceptance Criteria

- [ ] `rate_limit to: 60, within: 1.minute` on `PeakFlowReadingsController#create`
- [ ] `rate_limit to: 10, within: 1.minute` on `SettingsController#update_personal_best`
- [ ] All existing tests still pass (rate limiting uses store; test environment uses memory store)

## Work Log

- 2026-03-07: Identified by security-sentinel during Phase 6 code review
