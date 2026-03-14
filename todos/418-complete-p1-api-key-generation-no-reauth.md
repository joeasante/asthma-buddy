---
status: pending
priority: p1
issue_id: 418
tags: [code-review, security, authentication, api]
dependencies: []
---

# API key generation does not require re-authentication

## Problem Statement

The `Settings::ApiKeysController#create` action generates a new API key without requiring the user to re-enter their password or complete an MFA challenge. If an attacker gains access to an active web session (session hijacking, XSS, unattended browser), they can silently generate an API key that provides persistent access to all PHI endpoints even after the session expires. The API key never expires and grants full read access.

## Findings

- **Source**: security-sentinel (Finding #4)
- **Location**: `app/controllers/settings/api_keys_controller.rb:11-17`
- The MFA setup flow requires password confirmation, but API key generation does not
- The key replaces any existing key without confirmation (no `turbo_confirm` on Generate button when key exists)
- Combined with no API key expiration (Finding #6), this escalates session compromise to indefinite persistent access

## Proposed Solutions

### Option A: Require password confirmation before key generation
- **Approach**: Add a confirmation step similar to the MFA setup flow — user must enter their password before `create` executes
- **Pros**: Standard security practice, consistent with MFA setup flow
- **Cons**: Extra step in the UI, requires a new confirmation form
- **Effort**: Medium
- **Risk**: Low

### Option B: Add turbo_confirm on Generate button when key exists
- **Approach**: Add `data: { turbo_confirm: "..." }` to the Generate button when `@has_key` is true (matching the Revoke button pattern)
- **Pros**: Quick fix, prevents accidental key replacement
- **Cons**: Does not address the session hijacking vector — an attacker can still click through the dialog
- **Effort**: Small
- **Risk**: Low

## Recommended Action

_To be filled during triage_

## Technical Details

- **Affected files**: `app/controllers/settings/api_keys_controller.rb`, `app/views/settings/api_keys/show.html.erb`
- **Components**: API key management, authentication

## Acceptance Criteria

- [ ] User must re-authenticate (password or MFA) before generating an API key
- [ ] Generate button shows confirmation dialog when a key already exists
- [ ] Test covers the re-authentication requirement

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from code review | security-sentinel identified session escalation risk |

## Resources

- PR #24: https://github.com/joeasante/asthma-buddy/pull/24
- Related: `todos/401-complete-p2-no-rate-limit-password-reauth.md`
