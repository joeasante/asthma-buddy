---
status: pending
priority: p1
issue_id: "378"
tags: [code-review, agent-native, rails]
dependencies: []
---

## Problem Statement
`Admin::SiteSettingsController#toggle_registration` only does `redirect_back` — no `format.json` block. This violates the project's own convention (ApplicationController line 22-23: "Every resource action that creates/modifies data must support format.json"). An agent calling POST with Accept: application/json gets 406 Not Acceptable. Also, registration_open status is not included in the admin dashboard JSON response.

## Findings
The toggle_registration action uses a bare `redirect_back` without a `respond_to` block. All other mutation endpoints in the application follow the `respond_to do |format|` pattern with both `format.html` and `format.json` branches. This makes the registration toggle inaccessible to API/agent consumers.

## Proposed Solutions
### Option A: Add respond_to block with format.json and include registration_open in admin dashboard JSON
- Add `respond_to` block with `format.json` returning `{ registration_open: SiteSetting.registration_open? }`, and add `registration_open` to admin dashboard JSON
- Pros: 2-line fix, consistent with all other controllers
- Cons: none
- Effort: Small
- Risk: Low

## Acceptance Criteria
- [ ] `POST /admin/site_settings/toggle_registration.json` returns 200 with JSON body containing `registration_open` key
- [ ] `GET /admin.json` includes `registration_open` key
