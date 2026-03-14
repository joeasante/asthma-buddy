---
status: pending
priority: p2
issue_id: 420
tags: [code-review, security, api, authentication]
dependencies: []
---

# API keys never expire

## Problem Statement

API keys have no expiration. The `api_key_created_at` timestamp is stored but never checked during authentication in `authenticate_by_api_key`. A compromised key provides indefinite access to all PHI endpoints until manually revoked.

## Findings

- **Source**: security-sentinel (Finding #6)
- **Location**: `app/models/concerns/api_authenticatable.rb:7-12`
- `api_key_created_at` is stored but unused during auth
- No `api_key_last_used_at` tracking exists to detect stale keys

## Proposed Solutions

### Option A: Add expiry check in authenticate_by_api_key
- **Approach**: Check `api_key_created_at` against a configurable TTL (e.g., 90 days). Return nil if expired.
- **Effort**: Small
- **Risk**: Low (may break existing integrations if keys are old)

### Option B: Add last-used tracking and stale key warnings
- **Approach**: Update `api_key_last_used_at` on each API auth. Send email warnings for keys approaching expiry.
- **Effort**: Medium
- **Risk**: Low

## Acceptance Criteria

- [ ] Expired keys return 401
- [ ] UI displays expiry date
- [ ] Test covers expired key rejection

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from code review | security-sentinel identified indefinite access window |

## Resources

- PR #24: https://github.com/joeasante/asthma-buddy/pull/24
