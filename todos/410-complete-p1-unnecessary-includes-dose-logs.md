---
status: complete
priority: p1
issue_id: "410"
tags: [code-review, performance, api, n-plus-one]
dependencies: []
---

# Medications API Eagerly Loads dose_logs But Never Uses Them

## Problem Statement

`MedicationsController#index` includes `.includes(:dose_logs)` but the JSON response never references dose log data. This eagerly loads all dose logs for every medication in the result set for no reason. A user with 5 medications and 1,000 dose logs per medication loads 5,000 ActiveRecord objects into memory that are immediately discarded.

## Findings

**Flagged by:** kieran-rails-reviewer, performance-oracle, pattern-recognition-specialist

**Location:** `app/controllers/api/v1/medications_controller.rb`, line 9

```ruby
scope = policy_scope(Medication).includes(:dose_logs).order(created_at: :desc)
```

The JSON response (lines 13-27) only uses: `id`, `name`, `medication_type`, `dose_unit`, `standard_dose_puffs`, `doses_per_day`, `starting_dose_count`, `remaining_doses`, `created_at`. None of these come from dose_logs.

## Proposed Solutions

### Option A: Remove `.includes(:dose_logs)` (Recommended)

```ruby
scope = policy_scope(Medication).order(created_at: :desc)
```

- **Pros:** Eliminates wasteful query and memory allocation
- **Cons:** None — the data is not used
- **Effort:** Small (1 min)
- **Risk:** None (verify `remaining_doses` is a column, not computed from dose_logs)

## Acceptance Criteria

- [ ] `.includes(:dose_logs)` removed from medications API
- [ ] All tests pass
- [ ] JSON response unchanged

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 28 code review | 3 agents flagged this |
