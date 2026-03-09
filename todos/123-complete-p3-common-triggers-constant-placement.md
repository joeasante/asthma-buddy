---
status: pending
priority: p3
issue_id: "123"
tags: [code-review, rails, quality, symptom-log, convention]
dependencies: []
---

# `COMMON_TRIGGERS` constant placed between `enum` declarations — move below enums

## Problem Statement

In `app/models/symptom_log.rb`, `COMMON_TRIGGERS` is declared between the `symptom_type` and `severity` enum declarations. Rails convention groups macro-style class methods (`belongs_to`, `has_many`, `enum`, `validates`) before constant declarations. The current placement looks like the constant belongs to the `symptom_type` enum.

## Findings

- `app/models/symptom_log.rb:8-10` — `COMMON_TRIGGERS` between two `enum` declarations
- `app/models/peak_flow_reading.rb` — `GREEN_ZONE_THRESHOLD`, `YELLOW_ZONE_THRESHOLD` declared after all enum/validates macros

## Proposed Solutions

### Option A: Move COMMON_TRIGGERS below enum declarations
Place it after the last `enum` block and before `validates`.

**Effort:** Trivial | **Risk:** Low

## Recommended Action

Option A.

## Technical Details

- **Affected file:** `app/models/symptom_log.rb`

## Acceptance Criteria

- [ ] `COMMON_TRIGGERS` appears after all `enum` blocks in `symptom_log.rb`

## Work Log

- 2026-03-08: Identified by pattern-recognition-specialist during PR review
