---
status: pending
priority: p2
issue_id: 448
tags: [code-review, agent-native, billing, api]
dependencies: []
---

# Add API Endpoint for Subscription/Account Status

## Problem Statement

0 of 7 billing capabilities are API-accessible. An API client that receives a 403 ("API access requires an active premium subscription") has no programmatic way to check their plan, subscription status, trial end date, or feature limits. The model layer (`PlanLimits`) has all the necessary methods — the gap is purely at the controller/routing layer.

## Proposed Solution

Add `GET /api/v1/me` returning:
```json
{
  "data": {
    "plan": "premium",
    "subscription_status": "trialing",
    "trial_ends_at": "2026-04-14T00:00:00Z",
    "next_billing_date": "2026-04-14T00:00:00Z",
    "features": {
      "symptom_log_history_days": null,
      "peak_flow_history_days": null
    }
  }
}
```

This endpoint should authenticate via API key but NOT require premium (so users can introspect their own account status regardless of plan).

- **Effort**: Small (one controller, one route)
- **Risk**: None

## Acceptance Criteria

- [ ] `GET /api/v1/me` returns account/subscription info
- [ ] Accessible to both free and premium API key holders
- [ ] Returns 401 for invalid/missing API key
