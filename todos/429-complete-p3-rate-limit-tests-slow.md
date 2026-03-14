---
status: pending
priority: p3
issue_id: 429
tags: [code-review, testing, performance]
dependencies: []
---

# Rate limiting tests make 300+ HTTP requests — slow test suite

## Problem Statement

Three test cases each make 61 HTTP requests (total ~307 requests in one test file). This is slow and could become a CI bottleneck. Consider lowering the throttle limit in test setup to make tests faster.

## Findings

- **Source**: kieran-rails-reviewer (Finding #12)
- **Location**: `test/controllers/api/v1/rate_limiting_test.rb`

## Proposed Solutions

### Option A: Override throttle limit in test setup
- **Approach**: Set the throttle limit to 3/minute in test setup and send 4 requests instead of 61
- **Effort**: Small
- **Risk**: Low

## Acceptance Criteria

- [ ] Rate limit tests complete in under 5 seconds
- [ ] Tests still verify throttling behavior

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from code review | |

## Resources

- PR #24: https://github.com/joeasante/asthma-buddy/pull/24
