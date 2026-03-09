---
status: pending
priority: p1
issue_id: "111"
tags: [code-review, security, rate-limiting, rails, profiles]
dependencies: []
---

# Missing rate limiting on `ProfilesController#update` — password change brute-forceable

## Problem Statement

`ProfilesController#update` accepts a `current_password` parameter and performs an `authenticate` call to verify it before allowing a password change. There is no rate limiting on this action. Every other sensitive write action in this codebase has a `rate_limit` declaration: `SessionsController#create`, `PasswordsController#create`, `RegistrationsController#create`, `EmailVerificationsController#create`, `PeakFlowReadingsController#create`. The profile update endpoint is the only sensitive write action without rate limiting.

## Findings

- `app/controllers/profiles_controller.rb` — no `rate_limit` declaration
- `app/controllers/sessions_controller.rb` — `rate_limit to: 10, within: 3.minutes, only: :create`
- `app/controllers/passwords_controller.rb` — `rate_limit to: 3, within: 5.minutes, only: :create`
- An attacker with temporary session access can attempt unlimited password changes without throttling

## Proposed Solutions

### Option A: Add rate_limit to ProfilesController (Recommended)
```ruby
# app/controllers/profiles_controller.rb
rate_limit to: 10, within: 3.minutes, only: :update
rate_limit to: 20, within: 1.minute, only: :update_personal_best
```
Mirror the pattern from `SessionsController`. Add a `respond_to` handler for `format.json` with the rate limit exceeded error.

**Pros:** Consistent with codebase security posture.
**Effort:** Small | **Risk:** Low

## Recommended Action

Option A — one line per action, matching the established pattern.

## Technical Details

- **Affected files:** `app/controllers/profiles_controller.rb`
- **Reference:** `app/controllers/sessions_controller.rb` line 3

## Acceptance Criteria

- [ ] `rate_limit` present on `ProfilesController#update`
- [ ] `rate_limit` present on `ProfilesController#update_personal_best`
- [ ] Rate limit response is sensible for both HTML (redirect with flash) and JSON (status 429) callers

## Work Log

- 2026-03-08: Identified by security-sentinel, architecture-strategist, kieran-rails-reviewer, and pattern-recognition-specialist
