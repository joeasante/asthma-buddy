---
status: pending
priority: p2
issue_id: "136"
tags: [code-review, security, validation, symptom-logs]
dependencies: []
---

# Triggers Stored Without Server-Side Whitelist Validation

## Problem Statement

`triggers` values are accepted from params and persisted without validation against `COMMON_TRIGGERS`. A malicious or misconfigured client can store arbitrary strings in the `triggers` column. While this is not a direct injection risk (triggers are displayed as text, not executed), it allows database pollution, breaks expected UI behavior, and creates inconsistent data that downstream features (analytics, AI suggestions) cannot rely on.

Flagged by: security-sentinel (F-01), architecture-strategist.

## Findings

**File:** `app/controllers/symptom_logs_controller.rb`, strong params

```ruby
params.require(:symptom_log).permit(:symptom_type, :severity, :recorded_at, :notes, triggers: [])
```

No validation that each element of `triggers[]` is a member of `SymptomLog::COMMON_TRIGGERS`.

**Model:** `app/models/symptom_log.rb` — no validation on triggers content.

## Proposed Solutions

**Solution A — Model validation (recommended):**
```ruby
validate :triggers_are_known, if: -> { triggers.present? }

private

def triggers_are_known
  unknown = triggers - COMMON_TRIGGERS
  errors.add(:triggers, "contains unknown values: #{unknown.join(', ')}") if unknown.any?
end
```

**Solution B — Sanitize in the setter instead of validating:**
```ruby
def triggers=(value)
  values = value.is_a?(Array) ? value : []
  sanitized = values & COMMON_TRIGGERS  # intersection: only known triggers kept
  write_attribute(:triggers, sanitized.to_json)
end
```
Silently drops unknown values rather than raising a validation error. Good for API tolerance; bad for debugging data quality.

**Solution C — Controller-level filter:**
```ruby
permitted_triggers = params[:symptom_log][:triggers]&.select { |t| SymptomLog::COMMON_TRIGGERS.include?(t) }
```

## Recommended Action

Solution A (model validation) for the primary path. For the JSON API, the error will surface as a standard validation error with `422 Unprocessable Entity`.

## Acceptance Criteria

- [ ] Model validation rejects `triggers` containing values not in `COMMON_TRIGGERS`
- [ ] `symptom_log_test.rb` tests that unknown trigger values are rejected
- [ ] Valid trigger values still save correctly
- [ ] JSON API returns 422 with descriptive error when unknown triggers submitted

## Work Log

- 2026-03-08: Identified by security-sentinel (F-01) and architecture-strategist
