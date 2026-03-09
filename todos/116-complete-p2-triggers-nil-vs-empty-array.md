---
status: pending
priority: p2
issue_id: "116"
tags: [code-review, rails, database, migration, symptom-log, quality]
dependencies: []
---

# `triggers` column has no default — model returns `nil` not `[]` for new records

## Problem Statement

The `add_triggers_to_symptom_logs` migration adds `triggers:text` with no default value. `serialize :triggers, coder: JSON` deserializes a SQL `NULL` as Ruby `nil`, not `[]`. Views defensively call `Array(symptom_log.triggers)` to handle this, indicating the model is not self-consistent — callers must know that triggers can be nil. Existing symptom logs created before this migration have `NULL` in the column.

## Findings

- `db/migrate/20260308095602_add_triggers_to_symptom_logs.rb` — `add_column :symptom_logs, :triggers, :text` — no `default: '[]'`
- `app/views/symptom_logs/_timeline_row.html.erb` — `Array(symptom_log.triggers)` defensive wrapper
- `app/views/symptom_logs/_form.html.erb` — `Array(symptom_log.triggers).include?(trigger)` defensive wrapper
- `app/models/symptom_log.rb` — no `after_initialize` guard

## Proposed Solutions

### Option A: New migration to add default + model guard (Recommended)
```ruby
# New migration
change_column_default :symptom_logs, :triggers, from: nil, to: '[]'
# Backfill existing NULLs
SymptomLog.where(triggers: nil).update_all(triggers: '[]')
```
```ruby
# app/models/symptom_log.rb
after_initialize { self.triggers ||= [] }
```
Remove `Array()` wrappers from views.

**Effort:** Small | **Risk:** Low

### Option B: Model-only guard (no migration)
Keep column nullable, add `after_initialize { self.triggers ||= [] }` to guarantee the Ruby object always has an array.
Still need to keep `Array()` in serialized JSON for truly raw DB reads.

**Effort:** Small | **Risk:** Low

## Recommended Action

Option A — fix at the database level for consistency.

## Technical Details

- **Affected files:** `app/models/symptom_log.rb`, new migration needed, `app/views/symptom_logs/_timeline_row.html.erb`, `_form.html.erb`

## Acceptance Criteria

- [ ] `symptom_log.triggers` always returns an Array (never nil)
- [ ] New symptom logs default to `[]` triggers without explicit assignment
- [ ] View code uses `symptom_log.triggers` directly without `Array()` guard

## Work Log

- 2026-03-08: Identified by data-migration-expert and pattern-recognition-specialist
