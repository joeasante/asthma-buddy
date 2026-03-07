---
status: pending
priority: p2
issue_id: "085"
tags: [code-review, security, privacy, phi, hipaa]
dependencies: []
---

# PHI Log Filtering Incomplete — `symptom_log` Fields Not Filtered

## Problem Statement

`config/initializers/filter_parameter_logging.rb` filters `peak_flow_reading[value]`, `peak_flow_reading[recorded_at]`, and `personal_best_record[value]` from Rails logs, but does not filter `symptom_log` parameters. A user writing free-text symptom notes (e.g. "shortness of breath after visiting the cat shelter") would have that text visible in plaintext in the production log. Symptom notes, severity levels, and timestamps are PHI.

## Findings

**Flagged by:** security-sentinel (F-09)

**Current** (`config/initializers/filter_parameter_logging.rb`):
```ruby
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  /peak_flow_reading\[value\]/, /peak_flow_reading\[recorded_at\]/,
  /personal_best_record\[value\]/
]
```

**Missing:**
- `symptom_log[notes]` — free-text, most sensitive field in the app
- `symptom_log[severity]` — clinical severity rating (PHI)
- `symptom_log[recorded_at]` — timestamp of a symptom event (PHI)
- `personal_best_record[recorded_at]` — date of personal best measurement (PHI)

## Proposed Solutions

### Option A: Pattern-match all health model subkeys (Recommended)
**Effort:** Tiny | **Risk:** Very Low

```ruby
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  # Health data — prevent PHI from appearing in server logs
  /peak_flow_reading\[/, /personal_best_record\[/, /symptom_log\[/
]
```

Pattern-matching all subkeys of each health model namespace means new fields added to those models are automatically filtered without requiring an update here.

### Option B: Field-by-field enumeration
**Effort:** Small | **Risk:** Low

Enumerate each field explicitly for precision. More verbose but more explicit:

```ruby
/symptom_log\[notes\]/, /symptom_log\[severity\]/, /symptom_log\[recorded_at\]/,
/personal_best_record\[recorded_at\]/
```

## Recommended Action

Option A — broad pattern match for all health model parameters. Simpler, future-proof, and consistent with the intent of filtering all PHI from logs rather than tracking field-by-field.

## Technical Details

**Affected files:**
- `config/initializers/filter_parameter_logging.rb`

## Acceptance Criteria

- [ ] `symptom_log[notes]`, `symptom_log[severity]`, `symptom_log[recorded_at]` filtered from logs
- [ ] `personal_best_record[recorded_at]` filtered from logs
- [ ] `bin/rails test` passes with 0 failures
- [ ] Manual verification: submit a symptom log, check logs — PHI fields show `[FILTERED]`

## Work Log

- 2026-03-07: Identified by security-sentinel in Phase 6 code review
