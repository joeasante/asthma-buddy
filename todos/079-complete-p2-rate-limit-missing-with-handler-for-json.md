---
status: pending
priority: p2
issue_id: "079"
tags: [code-review, api, rails, agent-native]
dependencies: []
---

# `rate_limit` Missing `with:` Handler — JSON Callers Get HTML 429

## Problem Statement

`PeakFlowReadingsController` has `rate_limit to: 60, within: 1.minute, only: :create` with no `with:` response handler. Rails' default rate-limit response is an HTML page. A JSON agent caller that hits the limit receives an HTML 429 response they cannot parse, breaking the documented JSON contract. Every other rate-limited controller in the app that handles JSON provides a structured `with:` block.

## Findings

**Flagged by:** pattern-recognition-specialist (P2-2), agent-native-reviewer (P3), security-sentinel (F-06)

**Current** (`app/controllers/peak_flow_readings_controller.rb:4`):
```ruby
rate_limit to: 60, within: 1.minute, only: :create
```

**Pattern from `sessions_controller.rb`:**
```ruby
rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
  respond_to do |format|
    format.html { redirect_to new_session_path, alert: "Too many attempts. Try again later." }
    format.json { render json: { error: "Rate limit exceeded. Try again later." }, status: :too_many_requests }
  end
}
```

**Secondary concern:** 60 req/min for a health data write endpoint is 6x more permissive than all other sensitive endpoints (authentication, password reset all use 10/min). Consider lowering to 10/min to match the app's security posture.

## Proposed Solutions

### Option A: Add `with:` handler + lower rate (Recommended)
**Effort:** Small | **Risk:** Low

```ruby
rate_limit to: 10, within: 1.minute, only: :create, with: -> {
  respond_to do |format|
    format.html { redirect_to new_peak_flow_reading_path, alert: "Too many submissions. Try again in a moment." }
    format.json { render json: { error: "Rate limit exceeded. Try again later." }, status: :too_many_requests }
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        "flash-messages",
        partial: "shared/flash",
        locals: { message: "Too many submissions. Try again in a moment.", type: "alert" }
      ), status: :too_many_requests
    end
  end
}
```

### Option B: Add `with:` handler only (keep 60/min)
**Effort:** Tiny | **Risk:** Low

Keep the permissive limit, just add the JSON response handler. A user might legitimately submit several readings in quick succession if testing the form.

## Recommended Action

Option A — add `with:` handler and lower to 10/min. Matches the app's established security posture and fixes the JSON contract violation.

## Technical Details

**Affected files:**
- `app/controllers/peak_flow_readings_controller.rb`
- `test/controllers/peak_flow_readings_controller_test.rb` (add rate limit test)

## Acceptance Criteria

- [ ] Rate-limited JSON request returns `{ error: "..." }` with `429` status (not HTML)
- [ ] Rate-limited HTML request redirects with alert flash
- [ ] `bin/rails test` passes with 0 failures

## Work Log

- 2026-03-07: Identified by pattern-recognition-specialist and agent-native-reviewer in Phase 6 code review
