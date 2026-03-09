---
status: pending
priority: p3
issue_id: "145"
tags: [code-review, ruby, cleanup, symptom-logs]
dependencies: []
---

# Dead Double-Parse Branch in Triggers Getter After Migration

## Problem Statement

`SymptomLog#triggers` contains a double-parse fallback to handle historically double-encoded JSON data. Now that migration `20260308140000_normalize_double_encoded_triggers.rb` has run and normalized all existing records, this branch is dead code. It misleads readers into thinking double-encoding is still a live concern and complicates the method unnecessarily.

Flagged by: architecture-strategist.

## Findings

**File:** `app/models/symptom_log.rb`, `triggers` getter lines 12–14

```ruby
# Double-encoded: parsed is itself a JSON string — parse once more
result = JSON.parse(parsed)
result.is_a?(Array) ? result : []
```

After the normalization migration, `JSON.parse(raw)` will always return an Array (or raise `JSON::ParserError`). The branch where `parsed` is a String (double-encoded) can no longer be reached.

## Proposed Solution

Simplify the getter after confirming the migration ran successfully in production:

```ruby
def triggers
  raw = read_attribute(:triggers)
  return [] if raw.nil?
  return raw if raw.is_a?(Array)
  parsed = JSON.parse(raw)
  parsed.is_a?(Array) ? parsed : []
rescue JSON::ParserError
  []
end
```

The `return raw if raw.is_a?(Array)` guard can also likely be removed (the DB column stores JSON strings, not Ruby Arrays), but it is cheap and defensive — keep it.

## Acceptance Criteria

- [ ] Double-parse branch removed from `triggers` getter
- [ ] Method still returns `[]` for nil, for invalid JSON, and for valid `"[]"` strings
- [ ] All existing triggers tests pass
- [ ] **Prerequisite:** Confirm normalization migration has run in production first

## Work Log

- 2026-03-08: Identified by architecture-strategist. Do not resolve until normalization migration is confirmed in production.
