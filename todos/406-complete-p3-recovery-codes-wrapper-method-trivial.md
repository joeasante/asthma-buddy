---
status: pending
priority: p3
issue_id: 406
tags: [code-review, simplicity]
dependencies: []
---

# recovery_codes wrapper method is a trivial alias

## Problem Statement

`User#recovery_codes` (line 102-104) is a one-line delegation to private `recovery_codes_array`. The wrapper adds indirection for no reason.

## Findings

- **Source:** code-simplicity-reviewer agent

## Proposed Solutions

Rename `recovery_codes_array` to `recovery_codes` and make it public. Remove the wrapper.

## Acceptance Criteria

- [ ] Single `recovery_codes` method (no wrapper)
- [ ] All tests pass

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 27 code review | |
