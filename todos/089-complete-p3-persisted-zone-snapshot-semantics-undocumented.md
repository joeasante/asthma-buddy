---
status: pending
priority: p3
issue_id: "089"
tags: [code-review, rails, documentation, medical, data-integrity]
dependencies: []
---

# Persisted Zone Snapshot Semantics Undocumented

## Problem Statement

`PeakFlowReading` persists the `zone` column as a snapshot computed at save time. If a user later adds a personal best record with an earlier `recorded_at`, historical zone values on existing readings may no longer reflect what `compute_zone` would return today. This is a deliberate architectural choice (preserve what the user was told at the moment of recording), but it is not documented. A future developer adding a personal-best edit or delete feature would have no signal that they need to handle downstream zone recomputation.

## Findings

**Flagged by:** architecture-strategist (P2), kieran-rails-reviewer (P1)

**Current** (`app/models/peak_flow_reading.rb:13`):
```ruby
before_save { self.zone = compute_zone }
```

No comment explaining snapshot semantics.

## Proposed Solutions

### Option A: Add explanatory comment (Recommended)
**Effort:** Tiny | **Risk:** Zero

```ruby
# Zone is computed once at save time and persisted as a snapshot.
# This preserves the historical zone classification shown to the user at the moment of recording.
# IMPORTANT: If personal_best_records ever become editable or deletable, a background job
# (Solid Queue) must recompute zone for all affected peak_flow_readings. Without this,
# historical zone data will silently become stale.
before_save { self.zone = compute_zone }
```

### Option B: Remove persisted zone, compute dynamically
**Effort:** Large | **Risk:** Medium

Remove the `zone` column, compute on demand. Correct for any personal best change but adds a query-per-row for any list view. Only viable if personal bests frequently change retroactively (they don't in normal use).

## Recommended Action

Option A — add the comment. The persisted snapshot is the right design for this use case. The comment is the missing piece.

## Technical Details

**Affected files:**
- `app/models/peak_flow_reading.rb`

## Acceptance Criteria

- [ ] `before_save` callback has a comment explaining snapshot semantics and the recompute requirement
- [ ] No functional change

## Work Log

- 2026-03-07: Identified by architecture-strategist and kieran-rails-reviewer in Phase 6 code review
