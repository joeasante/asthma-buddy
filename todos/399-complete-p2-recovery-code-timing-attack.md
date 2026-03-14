---
status: pending
priority: p2
issue_id: 399
tags: [code-review, security, mfa]
dependencies: []
---

# Recovery code comparison vulnerable to timing attack

## Problem Statement

`User#verify_recovery_code` uses `Array#index` with standard string equality, which is not constant-time. An attacker measuring response times could theoretically extract valid recovery codes character by character.

## Findings

- **Source:** security-sentinel agent
- **File:** `app/models/user.rb`, line 68
- **Evidence:** `codes.index(normalized)` uses `==` internally
- **Practical risk:** Low over network (10-char hex codes, rate-limited to 5/min), but defense-in-depth warrants fixing for a health data app.

## Proposed Solutions

### Option A: Use secure_compare (Recommended)
Replace `codes.index(normalized)` with `codes.index { |c| ActiveSupport::SecurityUtils.secure_compare(c, normalized) }`
- **Effort:** Small (1 line)
- **Risk:** None

## Acceptance Criteria

- [ ] Recovery code verification uses `ActiveSupport::SecurityUtils.secure_compare`
- [ ] Existing recovery code tests pass

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 27 code review | |
