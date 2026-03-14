---
status: pending
priority: p3
issue_id: "389"
tags: [code-review, performance, rails]
dependencies: []
---

## Problem Statement
The admin dashboard view calls `SiteSetting.registration_open?` three times. Each call hits `Rails.cache.fetch` (Solid Cache). This is trivially avoidable by setting an instance variable in the controller.

## Findings
Three separate calls to `SiteSetting.registration_open?` were identified in the admin dashboard view template. While each individual call is fast (cache hit), the repetition is unnecessary overhead and a code smell.

## Proposed Solutions
### Option A: Set ivar in controller
Set `@registration_open = SiteSetting.registration_open?` in the admin dashboard controller action and use the ivar in the view. Effort: Small.

## Acceptance Criteria
- [ ] View references `@registration_open` not `SiteSetting.registration_open?`
- [ ] All tests pass
