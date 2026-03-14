---
status: pending
priority: p2
issue_id: 423
tags: [code-review, quality, dry, api]
dependencies: []
---

# Bearer token regex duplicated 3 times across codebase

## Problem Statement

The regex `/\ABearer\s+([a-f0-9]{64})\z/` appears in 3 locations: `base_controller.rb:53`, `rack_attack.rb:34`, and `rack_attack.rb:42`. If the token format ever changes, all 3 must be updated in lockstep.

## Findings

- **Source**: pattern-recognition-specialist, architecture-strategist
- The token extraction logic is also duplicated verbatim in both Rack::Attack throttle rules

## Proposed Solutions

### Option A: Extract to a shared constant
- **Approach**: Define `ApiAuthenticatable::BEARER_PATTERN = /\ABearer\s+([a-f0-9]{64})\z/` and reference it from both locations
- **Effort**: Small
- **Risk**: Low

## Acceptance Criteria

- [ ] Regex defined in one place
- [ ] All 3 locations reference the constant
- [ ] Tests pass

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from code review | Cross-validated by 2 agents |

## Resources

- PR #24: https://github.com/joeasante/asthma-buddy/pull/24
