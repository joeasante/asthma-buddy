---
status: complete
priority: p3
issue_id: "335"
tags: [code-review, cleanup, dead-code, medications]
dependencies: []
---

# Stale "Phase 13" Comment and Unused `DoseLog.for_medication` Scope

## Problem Statement

Two minor dead-code/stale items in the medications domain:

1. `app/models/medication.rb` contains a `# Phase 13:` comment that references a now-complete historical phase. These phase-specific comments become noise once the phase is done and confuse future developers reading the code.

2. `app/models/dose_log.rb` (or related file) defines a `for_medication` scope that is never called anywhere in the codebase. Dead scopes add cognitive overhead and suggest the caller was removed without cleaning up the model.

## Findings

**Flagged by:** code-simplicity-reviewer

- Stale `# Phase 13:` comment in `medication.rb`
- `DoseLog.for_medication` scope: defined but `grep` finds no call sites

## Proposed Solutions

### Option A: Delete both (Recommended)
Remove the stale comment and the unused scope.

**Pros:** Cleaner code; no dead weight
**Cons:** None — dead code has no value
**Effort:** Tiny
**Risk:** None

### Recommended Action

Option A.

## Technical Details

- **Files:** `app/models/medication.rb`, `app/models/dose_log.rb`
- Verify `for_medication` has no call sites with: `grep -r "for_medication" app/`

## Acceptance Criteria

- [ ] `# Phase 13` comment removed from `medication.rb`
- [ ] `DoseLog.for_medication` scope removed (after confirming no call sites)
- [ ] All tests pass

## Work Log

- 2026-03-12: Created from Milestone 2 code review — code-simplicity-reviewer finding
