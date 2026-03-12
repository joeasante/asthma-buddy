---
status: pending
priority: p2
issue_id: "295"
tags: [code-review, rails, performance, n-plus-one, health-events, api]
dependencies: []
---

# health_event_json illness_symptom_logs causes N+1 on ActionText notes

## Problem Statement
`HealthEventsController#health_event_json` runs a separate `symptom_logs` query for illness events, then iterates and calls `sl.notes&.to_plain_text` on each result. The query has no `.includes(:rich_text_notes)`, causing one additional SQL query per symptom log to load the ActionText body. For a 7-day illness with 14 symptom logs, this is 14 extra queries on `GET /health_events/:id.json`. Additionally, the HTML `show` action already loads `@illness_symptom_logs` with the correct includes, but the JSON path ignores it and re-queries independently.

## Findings
**Flagged by:** performance-oracle, security-sentinel (M-3)

**File:** `app/controllers/health_events_controller.rb`

```ruby
def health_event_json(event)
  if event.illness?
    illness_end = event.ended_at || Time.current
    symptom_logs = Current.user.symptom_logs         # <-- new query
      .where(recorded_at: event.recorded_at.beginning_of_day..illness_end.end_of_day)
      .order(recorded_at: :desc)
    data[:illness_symptom_logs] = symptom_logs.map do |sl|
      { ..., notes: sl.notes&.to_plain_text }         # <-- N+1 here
    end
  end
end
```

## Proposed Solutions

### Option A — Add includes to the query (Recommended)
```ruby
symptom_logs = Current.user.symptom_logs
  .where(...)
  .includes(:rich_text_notes)
  .order(recorded_at: :desc)
```
**Pros:** Eliminates N+1. One-line fix. **Effort:** Trivial. **Risk:** None.

### Option B — Reuse @illness_symptom_logs
Pass `@illness_symptom_logs` into `health_event_json` and use it when available (HTML show path). Falls back to the query for other callers (JSON index).
**Pros:** Eliminates duplicate query on show path too. **Cons:** Requires method signature change. **Effort:** Small. **Risk:** Low.

## Recommended Action

## Technical Details
- **File:** `app/controllers/health_events_controller.rb` — `health_event_json`
- **Impact:** N+1 queries proportional to symptom logs during illness period on JSON endpoint

## Acceptance Criteria
- [ ] `symptom_logs` query in `health_event_json` includes `.includes(:rich_text_notes)`
- [ ] JSON response for an illness event with 5+ symptom logs issues no more than 3 total queries

## Work Log
- 2026-03-12: Code review finding — performance-oracle, security-sentinel

## Resources
- Branch: dev
