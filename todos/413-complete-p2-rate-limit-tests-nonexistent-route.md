---
status: complete
priority: p2
issue_id: "413"
tags: [code-review, testing, api, rate-limiting]
dependencies: []
---

# Rate Limiting Tests Hit Non-Existent Route /api/v1/health

## Problem Statement

Every test in `rate_limiting_test.rb` sends requests to `GET /api/v1/health`, which does not exist in routes. Tests pass only because Rack::Attack throttles before routing, but this is fragile and the non-throttled requests would 404.

## Findings

**Flagged by:** kieran-rails-reviewer

**Location:** `test/controllers/api/v1/rate_limiting_test.rb`

## Proposed Solutions

### Option A: Use an actual API route (Recommended)

Change test requests to `GET /api/v1/symptom_logs` with valid auth headers.

- **Effort:** Small (5 min)
- **Risk:** None

## Acceptance Criteria

- [ ] Rate limit tests use a real API route
- [ ] All tests still pass

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 28 code review | kieran-rails-reviewer flagged |
