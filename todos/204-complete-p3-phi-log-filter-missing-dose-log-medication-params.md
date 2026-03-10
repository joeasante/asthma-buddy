---
status: complete
priority: p3
issue_id: "204"
tags: [code-review, security, phi, privacy, phase-15-1]
dependencies: []
---

# PHI Log Filter Missing `dose_log[` and `medication[` Params

## Problem Statement
`config/initializers/filter_parameter_logging.rb` already filters `peak_flow_reading[`, `personal_best_record[`, `symptom_log[`, and `health_event[` as PHI. But `dose_log[` and `medication[` params — which contain medication names, dose amounts, and timestamps — are absent from the filter list. When a user submits a dose log, the POST body with the medication name and `recorded_at` appears unfiltered in server logs. Medication names and dose timestamps are PHI under HIPAA.

## Findings
- **File:** `config/initializers/filter_parameter_logging.rb`
- Existing filters cover peak flow, personal best, symptoms, health events
- Missing: `dose_log[`, `medication[`
- These params are written by `Settings::DoseLogsController` and `Settings::MedicationsController`
- Security agent rated this P3 (does not affect application behaviour; defence-in-depth)
- The `RelieverUsageController` only accepts a `weeks` param — not PHI — so this is about adjacent write controllers surfaced by this review

## Proposed Solutions

### Option A (Recommended): Add missing patterns
```ruby
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  /peak_flow_reading\[/, /personal_best_record\[/, /symptom_log\[/, /health_event\[/,
  /dose_log\[/, /medication\[/
]
```
- Effort: Very small (one-liner addition)
- Risk: None — affects only log output, not application behaviour

## Recommended Action

## Technical Details
- Affected files: `config/initializers/filter_parameter_logging.rb`

## Acceptance Criteria
- [ ] `dose_log[*` params filtered from server logs
- [ ] `medication[*` params filtered from server logs
- [ ] Existing filters unchanged

## Work Log
- 2026-03-10: Identified by security-sentinel in Phase 15.1 review
