---
status: pending
priority: p2
issue_id: "155"
tags: [code-review, security, rate-limiting, health-events]
dependencies: []
---

# `HealthEventsController` Missing Rate Limiting on Mutations

## Problem Statement

`HealthEventsController` has no `rate_limit` declaration on its mutation actions (`create`, `update`, `destroy`). Every other mutation-capable controller in the codebase uses Rails 8's built-in `rate_limit`. An authenticated user (or a compromised session) can flood create/destroy actions with no throttle.

## Findings

**Flagged by:** security-sentinel (P2)

**Location:** `app/controllers/health_events_controller.rb`

**Controllers that DO have rate_limit (reference pattern):**
- `SymptomLogsController` — `rate_limit to: 10, within: 1.minute, only: %i[create update destroy]`
- `PeakFlowReadingsController`
- `SessionsController`, `PasswordsController`, `RegistrationsController`

**`HealthEventsController` has NO rate_limit.**

**Risk:**
1. Flood `POST /medical-history` → unlimited health event records created, exhausting storage
2. Script `DELETE /medical-history/:id` calls → bulk-delete all of a user's medical history under a compromised session
3. Medical history is more sensitive than most data — losing it cannot be undone

## Proposed Solutions

### Option A — Add `rate_limit` consistent with `SymptomLogsController` (Recommended)

```ruby
class HealthEventsController < ApplicationController
  before_action :require_authentication
  before_action :set_health_event, only: %i[edit update destroy]

  rate_limit to: 10, within: 1.minute, only: %i[create update destroy], with: -> {
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("flash-messages") {
          tag.div(id: "flash-messages", data: { controller: "toast",
            "toast-message": "Too many submissions. Try again in a moment.",
            "toast-variant": "alert" })
        }, status: :too_many_requests
      }
      format.html { redirect_to health_events_path, alert: "Too many submissions. Try again in a moment." }
    end
  }
```

**Effort:** Small
**Risk:** None

## Acceptance Criteria

- [ ] `rate_limit` declared on `HealthEventsController` for `create`, `update`, `destroy`
- [ ] Rate limit threshold consistent with `SymptomLogsController`
- [ ] `bin/rails test test/controllers/health_events_controller_test.rb` passes

## Work Log

- 2026-03-09: Identified by security-sentinel during `ce:review` of Phase 15.

## Resources

- `app/controllers/symptom_logs_controller.rb` — reference rate_limit implementation
