---
status: pending
priority: p2
issue_id: "385"
tags: [code-review, documentation, rails]
dependencies: []
---

## Problem Statement
ApplicationController lines 64-67 comment says "Set ALLOWED_EMAILS=... to restrict login and disable registration for everyone else" — but registration is now controlled by SiteSetting, not ALLOWED_EMAILS. The comment is misleading.

## Findings
- Comment references ALLOWED_EMAILS as controlling registration
- Registration is now controlled by `SiteSetting`
- ALLOWED_EMAILS only restricts login
- Stale comment could mislead developers configuring the application

## Proposed Solutions
### Option A: Update comment to reflect current behavior
Update the comment to accurately state that registration is controlled by `SiteSetting` and that `ALLOWED_EMAILS` only restricts login.

**Pros:** Accurate docs.
**Effort:** Small.
**Risk:** Low.

## Acceptance Criteria
- [ ] Comment accurately describes current behavior
