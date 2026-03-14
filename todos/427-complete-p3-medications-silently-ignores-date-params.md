---
status: pending
priority: p3
issue_id: 427
tags: [code-review, api, ux]
dependencies: []
---

# Medications endpoint silently ignores date filter params

## Problem Statement

All other API resource controllers call `date_filter(scope)`, but `MedicationsController` does not. If a consumer passes `date_from` or `date_to` to the medications endpoint, the params are silently ignored. This is arguably correct (medications don't have `recorded_at`), but the silent ignoring could confuse API consumers.

## Findings

- **Source**: kieran-rails-reviewer (Finding #9)
- **Location**: `app/controllers/api/v1/medications_controller.rb`

## Proposed Solutions

### Option A: Document the difference
- **Approach**: No code change — document in API docs that medications don't support date filtering
- **Effort**: Small

### Option B: Return error when date params are passed
- **Approach**: Return 400 if `date_from` or `date_to` are present on endpoints that don't support filtering
- **Effort**: Small

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from code review | |

## Resources

- PR #24: https://github.com/joeasante/asthma-buddy/pull/24
