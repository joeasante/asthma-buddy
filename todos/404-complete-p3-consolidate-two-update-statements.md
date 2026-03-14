---
status: pending
priority: p3
issue_id: 404
tags: [code-review, performance, mfa]
dependencies: [398]
---

# Consolidate two UPDATE statements into one on login

## Problem Statement

Login completion runs two separate UPDATE statements against the same user row: `update_columns(last_sign_in_at)` then `update_all("sign_in_count = sign_in_count + 1")`. These should be a single UPDATE to eliminate one SQLite write transaction.

## Findings

- **Source:** performance-oracle agent
- **Note:** This will be resolved as part of todo 398 (extract sign-in tracking)

## Proposed Solutions

```ruby
User.where(id: user.id).update_all(
  ["last_sign_in_at = ?, sign_in_count = sign_in_count + 1", Time.current]
)
```

## Acceptance Criteria

- [ ] Single UPDATE statement per login
- [ ] Applied in both SessionsController and MfaChallengeController (or in shared method from todo 398)

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 27 code review | |
