---
status: complete
priority: p2
issue_id: 358
tags: [code-review, api, agent-native]
dependencies: []
---

## Problem Statement

New features (Health Report, admin dashboard, admin users, toggle_admin) only render HTML. No `respond_to` blocks with `format.json`. This breaks the JSON API parity pattern established by SessionsController, RegistrationsController, and DashboardController. 54% agent-accessibility score.

## Findings

The following controllers lack JSON API responses despite the codebase convention of providing `respond_to` blocks with `format.json`:

- `app/controllers/appointment_summaries_controller.rb` — Health Report show action, the most data-rich endpoint
- `app/controllers/admin/dashboard_controller.rb` — Admin dashboard stats
- `app/controllers/admin/users_controller.rb` — User listing and toggle_admin action

This breaks the pattern established by `SessionsController`, `RegistrationsController`, and `DashboardController`, which all support JSON responses for agent/API consumption.

## Proposed Solutions

**A) Add `respond_to` with `format.json` to all new controllers**
- Pros: Consistent with existing pattern; enables agent/API access to all features
- Cons: More work upfront; need to define JSON serialization for each endpoint

**B) Prioritize Health Report JSON first (most data-rich), admin later**
- Pros: Delivers highest-value endpoint first; admin JSON is lower priority
- Cons: Still leaves admin endpoints without JSON support

## Recommended Action



## Technical Details

**Affected files:**
- `app/controllers/appointment_summaries_controller.rb`
- `app/controllers/admin/dashboard_controller.rb`
- `app/controllers/admin/users_controller.rb`

## Acceptance Criteria

- [ ] GET /health-report.json returns structured health data
- [ ] GET /admin.json returns dashboard stats
- [ ] GET /admin/users.json returns paginated user list
- [ ] PATCH /admin/users/:id/toggle_admin.json returns success/error
