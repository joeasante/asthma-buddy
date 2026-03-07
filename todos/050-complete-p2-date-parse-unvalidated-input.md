---
status: pending
priority: p2
issue_id: "050"
tags: [code-review, security, error-handling, input-validation]
dependencies: []
---

# `Date.parse` on Unvalidated User Input — 500 Errors and Exception Leakage

## Problem Statement

`SymptomLogsController#index` calls `Date.parse` on raw query parameters without rescue. Any non-parseable date string (e.g., `?start_date=not-a-date`) raises `Date::Error` and returns a 500. In production this logs the full exception including the malicious input, generates noise in error monitoring, and reveals stack traces in development.

## Findings

**Flagged by:** security-sentinel (MEDIUM-02)

**Location:** `app/controllers/symptom_logs_controller.rb:12-13`

```ruby
@start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : nil
@end_date   = params[:end_date].present?   ? Date.parse(params[:end_date])   : nil
```

`Date.parse` raises `Date::Error` (subclass of `ArgumentError`) on invalid strings with no rescue clause.

**Reproduction:** `GET /symptom_logs?start_date=not-a-date` → 500

## Proposed Solutions

### Solution A: Rescue inline with nil fallback (Recommended)

```ruby
@start_date = params[:start_date].present? ? (Date.parse(params[:start_date]) rescue nil) : nil
@end_date   = params[:end_date].present?   ? (Date.parse(params[:end_date])   rescue nil) : nil
```

Treats malformed dates as absent. Silent and safe.

- **Effort:** Tiny
- **Risk:** Low

### Solution B: Strict format with strptime

```ruby
@start_date = begin
  Date.strptime(params[:start_date], "%Y-%m-%d")
rescue Date::Error, TypeError
  nil
end
```

Only accepts ISO 8601 `YYYY-MM-DD` format. Returns 200 with full date range if date is malformed.

- **Pros:** Strict validation, predictable format
- **Effort:** Small
- **Risk:** Low

### Solution C: Rescue at controller level

```ruby
rescue_from ArgumentError, with: :handle_invalid_params

def handle_invalid_params
  respond_to do |format|
    format.html { redirect_to symptom_logs_path, alert: "Invalid date filter." }
    format.json { render json: { error: "Invalid date parameter." }, status: :bad_request }
  end
end
```

- **Pros:** User-friendly error message
- **Effort:** Small
- **Risk:** Low

## Acceptance Criteria

- [ ] `GET /symptom_logs?start_date=not-a-date` returns 200 (or 400), not 500
- [ ] `GET /symptom_logs?start_date=2026-01-01` still works correctly
- [ ] Test coverage for malformed date parameters

## Work Log

- 2026-03-07: Created from security audit. security-sentinel MEDIUM-02.
