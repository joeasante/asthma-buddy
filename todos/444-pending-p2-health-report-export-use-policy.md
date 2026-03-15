---
status: pending
priority: p2
issue_id: 444
tags: [code-review, security, billing, authorization, architecture]
dependencies: []
---

# Move Health Report JSON Export Gate to Pundit Policy

## Problem Statement

The premium check for JSON export is inline in the controller (`if Current.user.premium?`) rather than through a Pundit policy method. The `after_action :verify_authorized` already passed from the HTML `authorize` call, so adding new export formats (CSV, PDF) could accidentally ship without premium gating. This also creates inconsistency with the Pundit-first authorization pattern used everywhere else.

## Proposed Solution

```ruby
# app/policies/appointment_summary_policy.rb
def export?
  user.premium?
end

# app/controllers/appointment_summaries_controller.rb
format.json do
  authorize :appointment_summary, :export?
  render json: health_report_json
end
```

- **Effort**: Small
- **Risk**: None

## Acceptance Criteria

- [ ] JSON export uses `authorize :appointment_summary, :export?`
- [ ] Free user GET /health-report.json returns 403
- [ ] Premium user GET /health-report.json returns 200
- [ ] Existing tests pass
