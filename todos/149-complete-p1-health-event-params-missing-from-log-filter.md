---
status: pending
priority: p1
issue_id: "149"
tags: [code-review, security, phi, logging, health-events]
dependencies: []
---

# `health_event` Params Missing from PHI Log Filter

## Problem Statement

The log parameter filter in `filter_parameter_logging.rb` covers `peak_flow_reading`, `personal_best_record`, and `symptom_log` — but not `health_event`. Every `POST /medical-history` (create) and `PATCH /medical-history/:id` (update) logs the full decoded parameter hash including `health_event[notes]` (free-text clinical notes), `health_event[event_type]` (medical category), and `health_event[recorded_at]` (date of medical event) in plain text.

## Findings

**Flagged by:** security-sentinel (P1)

**Location:** `config/initializers/filter_parameter_logging.rb`

**Current code:**
```ruby
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  /peak_flow_reading\[/, /personal_best_record\[/, /symptom_log\[/
]
```

**PHI in logs without this fix:**
- `health_event[event_type]` — e.g. `"hospital_visit"` — reveals medical event category
- `health_event[recorded_at]` — reveals date/time of medical event
- `health_event[ended_at]` — reveals duration of illness/hospital stay
- `health_event[notes]` — free-text field may contain "Started prednisolone, GP prescribed antibiotics, peak flow 190…" — detailed clinical narrative in plain text in production logs

Logs are routinely forwarded to third-party aggregation services (Datadog, Papertrail, Logtail), significantly expanding the PHI exposure surface. This is a GDPR / HIPAA-adjacent compliance requirement, not just best practice.

## Proposed Solutions

### Option A — Add regex pattern (Recommended)
```ruby
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  /peak_flow_reading\[/, /personal_best_record\[/, /symptom_log\[/, /health_event\[/
]
```

The `/health_event\[/` regex matches all subkeys (`health_event[notes]`, `health_event[event_type]`, `health_event[recorded_at]`, `health_event[ended_at]`) consistently with the existing approach.

**Pros:** One-line change. Consistent with existing pattern. Immediate protection.
**Effort:** Trivial
**Risk:** None

### Option B — Switch to `:health_event` symbol
```ruby
:health_event
```
Rails will filter any top-level key named `health_event` including nested hashes.

**Pros:** Slightly simpler.
**Cons:** Symbol-based filtering may be less predictable for nested params depending on Rails version.
**Effort:** Trivial

## Recommended Action

Option A — consistent with existing pattern in the file.

## Technical Details

**Affected file:** `config/initializers/filter_parameter_logging.rb`

**Verify fix works:**
```bash
bin/rails runner "Rails.application.config.filter_parameters.any? { |f| f.is_a?(Regexp) && f.match?('health_event[notes]') }"
# Should print: true
```

## Acceptance Criteria

- [ ] `/health_event\[/` pattern present in `filter_parameter_logging.rb`
- [ ] Rails filter parameters match `health_event[notes]`, `health_event[event_type]`, `health_event[recorded_at]`, `health_event[ended_at]`
- [ ] Test: `bin/rails runner "puts Rails.application.config.filter_parameters.inspect"` shows the new pattern

## Work Log

- 2026-03-09: Identified by security-sentinel during `ce:review` of Phase 15.

## Resources

- `config/initializers/filter_parameter_logging.rb` — current state
- Existing patterns: `/peak_flow_reading\[/`, `/symptom_log\[/` — reference
