---
status: pending
priority: p2
issue_id: 400
tags: [code-review, security, mfa, rails]
dependencies: []
---

# MFA-only actions accessible to users without MFA enabled

## Problem Statement

`Settings::SecurityController` actions like `recovery_codes`, `disable`, `regenerate_recovery_codes` are accessible to users who don't have MFA enabled. Visiting `/settings/security/recovery_codes` shows an empty grid. Visiting `/settings/security/disable` shows a form that would set already-nil columns to nil. Similarly, `setup` and `confirm_setup` should guard against users who already have MFA enabled.

## Findings

- **Source:** kieran-rails-reviewer agent
- **File:** `app/controllers/settings/security_controller.rb`
- **Note:** The UI hides links from non-MFA users, but direct URL access is unguarded.

## Proposed Solutions

### Option A: Add before_action guards (Recommended)
```ruby
before_action :require_mfa_enabled, only: %i[recovery_codes download_recovery_codes disable confirm_disable regenerate_recovery_codes confirm_regenerate_recovery_codes]
before_action :require_mfa_disabled, only: %i[setup confirm_setup]
```
- **Effort:** Small
- **Risk:** None

## Acceptance Criteria

- [ ] Non-MFA user visiting `/settings/security/disable` is redirected with alert
- [ ] MFA user visiting `/settings/security/setup` is redirected with alert
- [ ] Tests added for both guards

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 27 code review | |
