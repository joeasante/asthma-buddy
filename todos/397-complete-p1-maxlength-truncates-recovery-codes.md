---
status: pending
priority: p1
issue_id: 397
tags: [code-review, security, mfa, functional-bug]
dependencies: []
---

# maxlength: 6 on MFA challenge input truncates recovery codes

## Problem Statement

The MFA challenge form input has `maxlength: 6`, which is correct for 6-digit TOTP codes but truncates recovery codes. Recovery codes are generated with `SecureRandom.hex(5)` producing 10-character hex strings. A user entering a recovery code will have it silently truncated to 6 characters, causing verification to always fail.

This is a **functional bug** — recovery code login via the MFA challenge form is broken.

## Findings

- **Source:** kieran-rails-reviewer agent
- **File:** `app/views/mfa_challenge/new.html.erb`, line 22
- **Evidence:** `maxlength: 6` on the `otp_code` text field. Recovery codes are 10 chars (`SecureRandom.hex(5)`).
- **Pattern note:** The setup form at `app/views/settings/security/setup.html.erb` uses `maxlength: 6` with `pattern: "[0-9]*"` which is correct there (only TOTP codes, not recovery codes).

## Proposed Solutions

### Option A: Remove maxlength entirely (Recommended)
- **Pros:** Simplest fix, works for both TOTP (6 chars) and recovery codes (10 chars)
- **Cons:** No client-side length constraint
- **Effort:** Small (1 line)
- **Risk:** None

### Option B: Increase maxlength to 10
- **Pros:** Still provides a client-side constraint
- **Cons:** If recovery code length changes, must update here too
- **Effort:** Small (1 line)
- **Risk:** Low

## Recommended Action

Option A — remove `maxlength: 6` from the MFA challenge input. The field accepts both TOTP codes and recovery codes of different lengths.

## Technical Details

- **Affected files:** `app/views/mfa_challenge/new.html.erb`
- **Also update:** `pattern` attribute — currently `[0-9a-zA-Z]*` which is correct for both types

## Acceptance Criteria

- [ ] MFA challenge input accepts strings longer than 6 characters
- [ ] Recovery code login works end-to-end (enter 10-char code, verify succeeds)
- [ ] TOTP code login still works
- [ ] Test added verifying recovery code login through the form

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 27 code review | Recovery codes and TOTP codes share the same input field |

## Resources

- PR: Phase 27 MFA implementation (commits 95c18bb..HEAD)
