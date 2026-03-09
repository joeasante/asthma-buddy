---
status: pending
priority: p3
issue_id: "144"
tags: [code-review, ruby, clarity]
dependencies: []
---

# `triggers&.any?` Safe Navigator Is Redundant

## Problem Statement

`_timeline_row.html.erb` uses `symptom_log.triggers&.any?` but `SymptomLog#triggers` has a guaranteed non-nil return contract — every code path returns `[]` or a populated Array, never `nil`. The `&.` safe navigator misleads future readers into thinking `triggers` can return `nil`.

Flagged by: pattern-recognition-specialist.

## Findings

**File:** `app/views/symptom_logs/_timeline_row.html.erb`

```erb
<% if symptom_log.triggers&.any? %>
```

`SymptomLog#triggers` (lines 6–17 of the model) always returns an Array:
```ruby
def triggers
  ...
  return [] if raw.nil?
  return raw if raw.is_a?(Array)
  ...
rescue JSON::ParserError
  []
end
```

## Proposed Solution

```erb
<% if symptom_log.triggers.any? %>
```

## Acceptance Criteria

- [ ] `&.` removed from `symptom_log.triggers` call in timeline row partial
- [ ] No regressions in trigger display

## Work Log

- 2026-03-08: Identified by pattern-recognition-specialist
