---
status: pending
priority: p2
issue_id: "141"
tags: [code-review, security, rate-limiting, symptom-logs]
dependencies: []
---

# Rate Limiting Missing on `symptom_logs#create` and `#update`

## Problem Statement

`PeakFlowReadingsController#create` has rate limiting (`rate_limit to: 10, within: 1.minute`). `SymptomLogsController#create` and `#update` do not. A malicious user can spam symptom log creation/updates at unlimited speed. For a medical app storing clinical data, this is a concern for data integrity, storage costs, and abuse.

Flagged by: security-sentinel (F-05).

Note: `ProfilesController` rate limiting was already added (todo #111, complete). This todo covers the symptom logs gap specifically.

## Findings

**File:** `app/controllers/symptom_logs_controller.rb` — no `rate_limit` declaration.

**File:** `app/controllers/peak_flow_readings_controller.rb`, lines 6–19 — existing pattern to follow:

```ruby
rate_limit to: 10, within: 1.minute, only: :create, with: -> {
  respond_to do |format|
    format.html { redirect_to new_peak_flow_reading_path, alert: "Too many submissions. Try again in a moment." }
    format.turbo_stream { ... }
    format.json { render json: { error: "Rate limit exceeded. Try again later." }, status: :too_many_requests }
  end
}
```

## Proposed Solution

Add rate limiting to `SymptomLogsController` following the same pattern:

```ruby
rate_limit to: 10, within: 1.minute, only: %i[create update], with: -> {
  respond_to do |format|
    format.html { redirect_to new_symptom_log_path, alert: "Too many submissions. Try again in a moment." }
    format.turbo_stream { render turbo_stream: ..., status: :too_many_requests }
    format.json { render json: { error: "Rate limit exceeded. Try again later." }, status: :too_many_requests }
  end
}
```

## Acceptance Criteria

- [ ] `rate_limit` declaration added to `SymptomLogsController` for `create` and `update`
- [ ] Rate limit returns 429 with correct format-specific responses
- [ ] `symptom_logs_controller_test.rb` has a basic 429 test (or rate limiting is tested via the existing pattern)

## Work Log

- 2026-03-08: Identified by security-sentinel (F-05)
