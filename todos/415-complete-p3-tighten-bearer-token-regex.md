---
status: complete
priority: p3
issue_id: "415"
tags: [code-review, security, api, defense-in-depth]
dependencies: []
---

# Tighten Bearer Token Regex to Reject Invalid Formats

## Problem Statement

The Bearer token regex uses `(.+)` which accepts any string. Since tokens are always 64-character hex strings from `SecureRandom.hex(32)`, a stricter regex like `([a-f0-9]{64})` would reject obviously invalid tokens before the database lookup.

## Findings

**Flagged by:** pattern-recognition-specialist

**Location:** `app/controllers/api/v1/base_controller.rb`, line 47

```ruby
match = header.match(/\ABearer\s+(.+)\z/)
```

## Proposed Solutions

### Option A: Restrict to hex format

```ruby
match = header.match(/\ABearer\s+([a-f0-9]{64})\z/)
```

- **Effort:** Small (2 min)
- **Risk:** None (all valid tokens match this pattern)

## Acceptance Criteria

- [ ] Invalid token formats rejected without DB query
- [ ] Valid 64-char hex tokens still work
- [ ] All tests pass

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 28 code review | Defense-in-depth |
