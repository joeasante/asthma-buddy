---
status: pending
priority: p2
issue_id: "130"
tags: [code-review, api, agent-native, symptom-logs]
dependencies: []
---

# `triggers` Missing from All `symptom_log_json` Responses

## Problem Statement

`triggers` is accepted in `symptom_log_params`, persisted to the database, and readable via `log.triggers` — but it is never included in the `symptom_log_json` serializer. Agents logging symptoms with triggers cannot confirm the triggers were saved. Agents reading the symptom log index see no triggers on any record.

Flagged by: agent-native-reviewer.

## Findings

**File:** `app/controllers/symptom_logs_controller.rb`, `symptom_log_json` private method

```ruby
def symptom_log_json(log)
  log.as_json(only: %i[id symptom_type severity recorded_at created_at]).merge(
    notes: log.notes.to_plain_text
  )
end
```

`log.triggers` calls the model's custom deserializer which returns a clean Array. It just never gets called from the serializer.

## Proposed Solution

```ruby
def symptom_log_json(log)
  log.as_json(only: %i[id symptom_type severity recorded_at created_at]).merge(
    notes:    log.notes.to_plain_text,
    triggers: log.triggers
  )
end
```

## Acceptance Criteria

- [ ] `POST /symptom_logs` JSON response includes `triggers` array
- [ ] `PATCH /symptom_logs/:id` JSON response includes `triggers` array
- [ ] `GET /symptom_logs` JSON response includes `triggers` on each record
- [ ] `symptom_logs_controller_test.rb` asserts `triggers` key in create/update/index JSON responses

## Work Log

- 2026-03-08: Identified by agent-native-reviewer
