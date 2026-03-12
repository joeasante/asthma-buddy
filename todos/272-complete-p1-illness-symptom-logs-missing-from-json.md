---
status: complete
priority: p1
issue_id: "272"
tags: [code-review, rails, agent-native, api, health-events]
dependencies: []
---

# Illness-correlated symptom logs missing from health event JSON

## Problem Statement

When an illness event is shown in the UI, `@illness_symptom_logs` is populated with all symptom logs that fall within the illness window. This new feature (added in this PR) gives the user clinically useful correlation — "during this illness I had 5 wheezing episodes." The `health_event_json` serialiser does not include this data, so the JSON response for an illness event is indistinguishable from a non-illness event.

An agent retrieving an illness event cannot see what symptoms were recorded during that illness — precisely the correlation a clinical agent or automated summary generator would use to understand the severity of an episode.

## Findings

- **File:** `app/controllers/health_events_controller.rb:8–19` — `@illness_symptom_logs` populated in `show`
- **File:** `app/controllers/health_events_controller.rb:89–96` — `health_event_json` method does NOT include illness logs
- **Agent:** agent-native-reviewer

```ruby
# Current health_event_json — misses illness_symptom_logs
def health_event_json(event)
  {
    id:         event.id,
    event_type: event.event_type,
    # ... no illness_symptom_logs
  }
end
```

## Proposed Solutions

### Option A — Conditional inclusion in `health_event_json` (Recommended)

In `health_event_json`, check `event.illness?` and conditionally include serialised symptom logs:

```ruby
def health_event_json(event)
  json = { id: event.id, event_type: event.event_type, ... }
  if event.illness? && @illness_symptom_logs
    json[:illness_symptom_logs] = @illness_symptom_logs.map do |log|
      { id: log.id, recorded_at: log.recorded_at, severity: log.severity,
        symptom_type: log.symptom_type, notes: log.notes.to_plain_text }
    end
  end
  json
end
```

**Pros:** Follows existing pattern. Symptom logs are only included when clinically relevant.
**Effort:** Small
**Risk:** Low

### Option B — Always include empty array for illness events

Always include `illness_symptom_logs: []` even when empty.

**Pros:** Consistent shape.
**Cons:** Implies a missing feature when empty.
**Effort:** Trivial
**Risk:** Low

## Recommended Action

Option A — conditional inclusion with the symptom log fields most useful for clinical context.

## Technical Details

- **Affected files:** `app/controllers/health_events_controller.rb`
- Note: `@illness_symptom_logs` is already loaded with `includes(:rich_text_notes)` — no extra query needed

## Acceptance Criteria

- [ ] `GET /medical-history/:id.json` for an illness event includes `illness_symptom_logs` array
- [ ] Each symptom log entry includes `id`, `recorded_at`, `severity`, `symptom_type`, `notes`
- [ ] Non-illness event JSON does not include `illness_symptom_logs` key
- [ ] Controller test covers both illness and non-illness JSON responses

## Work Log

- 2026-03-11: Identified by agent-native-reviewer during code review of dev branch
