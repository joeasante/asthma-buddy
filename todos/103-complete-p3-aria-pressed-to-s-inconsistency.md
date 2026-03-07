---
status: pending
priority: p3
issue_id: "103"
tags: [code-review, rails, accessibility, consistency]
dependencies: []
---

# `aria: { pressed: (bool).to_s }` in peak flow filter bar inconsistent with symptom logs reference

## Problem Statement

`_filter_bar.html.erb` (peak flow) calls `.to_s` on the `aria: { pressed: }` boolean, while `_filter_bar.html.erb` (symptom logs) passes the raw boolean. Both produce identical HTML (`"true"` / `"false"`) because Rails serialises boolean attributes to strings automatically. The explicit `.to_s` implies uncertainty about Rails' attribute handling and creates a visual inconsistency between the two files.

## Findings

**Flagged by:** pattern-recognition-specialist (P2-C)

**Symptom logs (reference):**
```erb
aria: { pressed: active_preset == value },
```

**Peak flow (new):**
```erb
aria: { pressed: (active_preset == value).to_s },
```

Both render identically. The `.to_s` call is unnecessary noise.

## Proposed Solutions

### Option A: Remove `.to_s` (Recommended, 1-char change)

```erb
aria: { pressed: active_preset == value },
```

- **Effort:** Tiny
- **Risk:** None — identical rendered output

## Recommended Action

Option A.

## Technical Details

- **Affected files:** `app/views/peak_flow_readings/_filter_bar.html.erb`

## Acceptance Criteria

- [ ] `aria: { pressed: active_preset == value }` (no `.to_s`) in peak flow filter bar
- [ ] HTML output unchanged (`aria-pressed="true"` / `aria-pressed="false"`)

## Work Log

- 2026-03-07: Identified during Phase 7 code review
