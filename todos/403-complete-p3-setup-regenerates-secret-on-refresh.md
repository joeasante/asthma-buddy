---
status: pending
priority: p3
issue_id: 403
tags: [code-review, mfa, ux]
dependencies: []
---

# Setup action regenerates secret on every page refresh

## Problem Statement

Every GET to `/settings/security/setup` generates a new `ROTP::Base32.random` and overwrites `session[:pending_otp_secret]`. If a user refreshes the page after scanning the QR code, their scanned code becomes invalid.

## Findings

- **Source:** security-sentinel agent
- **File:** `app/controllers/settings/security_controller.rb`, line 10

## Proposed Solutions

Use `||=` instead of `=`:
```ruby
session[:pending_otp_secret] ||= ROTP::Base32.random
```

## Acceptance Criteria

- [ ] Refreshing setup page keeps the same QR code
- [ ] Starting a new setup flow (after navigating away and back) generates a new secret

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 27 code review | |
