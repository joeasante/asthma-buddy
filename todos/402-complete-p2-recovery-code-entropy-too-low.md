---
status: pending
priority: p2
issue_id: 402
tags: [code-review, security, mfa]
dependencies: []
---

# Recovery code entropy (40 bits) below industry standard

## Problem Statement

Recovery codes use `SecureRandom.hex(5)` = 10 hex chars = 40 bits. Industry standard (GitHub, Google) uses 64+ bits. With rate limiting the practical risk is low, but for a health data app, stronger codes are better.

## Findings

- **Source:** security-sentinel agent
- **File:** `app/models/user.rb`, line 121

## Proposed Solutions

### Option A: Increase to hex(8) (Recommended)
One-line change: `SecureRandom.hex(8)` = 16 hex chars = 64 bits. Also add hyphens for readability (e.g., `a3f2b1c9-d0e4f5a6`).
- **Effort:** Small
- **Risk:** None — existing codes remain valid until regenerated

## Acceptance Criteria

- [ ] New recovery codes are 16 hex characters (64 bits)
- [ ] Codes include hyphen for readability
- [ ] `maxlength` on MFA challenge input updated accordingly (see todo 397)
- [ ] Existing tests updated for new code length

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 27 code review | |
