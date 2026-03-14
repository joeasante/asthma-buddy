---
status: pending
priority: p3
issue_id: 426
tags: [code-review, api, data-completeness]
dependencies: []
---

# Health events API response missing ended_at and ongoing fields

## Problem Statement

The health events API endpoint returns only `id`, `event_type`, `recorded_at`, `created_at`. The web JSON response includes `ended_at`, `event_type_label`, `ongoing`, and `formatted_duration`. An agent cannot determine whether an illness is ongoing or when it ended.

## Findings

- **Source**: agent-native-reviewer
- **Location**: `app/controllers/api/v1/health_events_controller.rb:13-19`

## Proposed Solutions

### Option A: Add missing fields to API response
- **Approach**: Add `ended_at`, `ongoing` (boolean), and `event_type_label` to the JSON hash
- **Effort**: Small
- **Risk**: Low

## Acceptance Criteria

- [ ] API response includes `ended_at`, `ongoing` fields
- [ ] Test verifies new fields

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from code review | |

## Resources

- PR #24: https://github.com/joeasante/asthma-buddy/pull/24
