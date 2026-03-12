---
status: complete
priority: p3
issue_id: "334"
tags: [code-review, json, api, consistency, dose-logs]
dependencies: []
---

# `DoseLogsController#index` Returns Bare JSON Array Instead of Wrapper Object

## Problem Statement

`Settings::DoseLogsController#index` returns a bare JSON array (`render json: @dose_logs`), while all other index endpoints in the project return a wrapper object with metadata (e.g. `{ dose_logs: [...], total: N, page: N }`). Agents and API consumers rely on a consistent envelope structure for pagination, filtering, and metadata. A bare array breaks this convention and makes the endpoint harder to extend.

## Findings

**Flagged by:** pattern-recognition-specialist

The project convention (established in prior todos 100, etc.) is:
```json
{
  "dose_logs": [...],
  "total": 42,
  "medication_id": 5
}
```

Current (incorrect):
```json
[{ "id": 1, "puffs": 2, ... }, ...]
```

## Proposed Solutions

### Option A: Wrap in envelope object (Recommended)
```ruby
format.json do
  render json: {
    dose_logs: @dose_logs.as_json(only: %i[id puffs created_at]),
    total: @dose_logs.size,
    medication_id: @medication.id
  }
end
```

**Pros:** Consistent with all other JSON endpoints
**Cons:** Breaking change if any consumer relies on the bare array (unlikely — it's internal)
**Effort:** Tiny
**Risk:** Low

### Recommended Action

Option A.

## Technical Details

- **File:** `app/controllers/settings/dose_logs_controller.rb`, `index` action

## Acceptance Criteria

- [ ] `GET /settings/medications/:id/dose_logs.json` returns `{ dose_logs: [...], total: N, medication_id: N }`
- [ ] Controller test verifies the wrapper structure

## Work Log

- 2026-03-12: Created from Milestone 2 code review — pattern-recognition-specialist finding
