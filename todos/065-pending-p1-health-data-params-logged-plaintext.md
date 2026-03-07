---
status: pending
priority: p1
issue_id: "065"
tags: [code-review, security, privacy, hipaa]
dependencies: []
---

# Health Data Params Not Filtered from Server Logs — Peak Flow Values Logged in Plaintext

## Problem Statement

Rails logs request parameters at INFO level. The Phase 6 endpoints submit health data (peak flow readings, personal best values) via `:value` and `:recorded_at` params — none of which are filtered. Every peak flow submission and personal best update appears verbatim in server logs:

```
Parameters: {"peak_flow_reading"=>{"value"=>"320", "recorded_at"=>"2026-03-07T14:30"}}
Parameters: {"personal_best_record"=>{"value"=>"480"}}
```

If logs are ever shipped to a third-party log aggregator (Datadog, Papertrail, Logtail), health data leaks to that service without a BAA. Even without a formal HIPAA obligation today, logging clinical readings is a privacy regression.

## Findings

**Flagged by:** security-sentinel

**Location:** `config/initializers/filter_parameter_logging.rb`

```ruby
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc
]
```

`:value` and `:recorded_at` are not in the filter list. Production log level is `info` (logs params by default).

**What is exposed:**
- Every peak flow reading value (L/min)
- Every personal best value (L/min)
- The timestamp of every reading

## Proposed Solutions

### Option A: Regex-based filter for health params (Recommended)

Add regex patterns that match only the health-data nested params, avoiding masking unrelated `:value` params elsewhere:

```ruby
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  # Health data — filter to prevent PHI in logs
  /peak_flow_reading\[value\]/,
  /peak_flow_reading\[recorded_at\]/,
  /personal_best_record\[value\]/
]
```

**Pros:** Surgical — only masks health-data params, not every param named `:value`
**Cons:** Requires updating when new health models are added
**Effort:** XSmall (5 minutes)
**Risk:** Zero

### Option B: Proc-based filter for all health endpoint paths

```ruby
Rails.application.config.filter_parameters << lambda do |key, value|
  if key.to_s.match?(/\A(peak_flow_reading|personal_best_record)\[/)
    value.replace("[FILTERED]")
  end
end
```

**Pros:** Automatically covers future fields on existing models
**Cons:** Slightly more complex; proc-based filtering is less common in Rails codebases
**Effort:** Small
**Risk:** Low

### Option C: Reduce log level to `:warn` in production

Set `config.log_level = :warn` in `config/environments/production.rb`. Parameters are only logged at `:debug` level.

**Pros:** Blanket solution — no params ever in logs
**Cons:** Loses useful INFO-level logs (request timing, controller/action); too broad a tradeoff
**Effort:** XSmall
**Risk:** Medium (loses observability)

## Recommended Action

Option A — fastest, most targeted, zero risk.

## Technical Details

**Affected file:**
- `config/initializers/filter_parameter_logging.rb`

**Future maintenance:** When new health-data models are added (e.g., medication logs, symptom detail fields), update this file.

## Acceptance Criteria

- [ ] `:value` on `peak_flow_reading` params is filtered (`[FILTERED]` in logs)
- [ ] `:recorded_at` on `peak_flow_reading` params is filtered
- [ ] `:value` on `personal_best_record` params is filtered
- [ ] Existing non-health `:value` params (if any) are not accidentally masked
- [ ] Verified by checking `Rails.application.config.filter_parameters` in rails console

## Work Log

- 2026-03-07: Identified by security-sentinel during Phase 6 code review

## Resources

- `config/initializers/filter_parameter_logging.rb`
- Rails guide: https://guides.rubyonrails.org/configuring.html#config-filter-parameters
