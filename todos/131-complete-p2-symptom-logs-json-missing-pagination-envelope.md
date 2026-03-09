---
status: pending
priority: p2
issue_id: "131"
tags: [code-review, api, agent-native, symptom-logs, pagination]
dependencies: []
---

# Symptom Logs JSON Index Missing Pagination Envelope

## Problem Statement

`GET /symptom_logs` with `Accept: application/json` returns a raw array. Agents cannot paginate, cannot confirm applied filters (including severity), and may silently process only the first 25 records believing that is the full dataset. The `peak_flow_readings#index` already implements the correct envelope pattern — this should be replicated.

Flagged by: agent-native-reviewer.

## Findings

**File:** `app/controllers/symptom_logs_controller.rb`, JSON format branch

The symptom logs JSON response returns a flat array with no metadata. Compare to `peak_flow_readings_controller.rb`:

```ruby
render json: {
  readings:        @peak_flow_readings.map { |r| peak_flow_reading_json(r) },
  current_page:    @current_page,
  total_pages:     @total_pages,
  per_page:        25,
  applied_filters: { preset:, start_date:, end_date: }
}
```

The symptom logs controller also handles a `severity` filter (`@active_severity`) which is absent from any JSON response metadata.

## Proposed Solution

Wrap the symptom logs JSON response in an envelope:

```ruby
format.json do
  render json: {
    symptom_logs:    @symptom_logs.map { |log| symptom_log_json(log) },
    current_page:    @current_page,
    total_pages:     @total_pages,
    per_page:        25,
    applied_filters: {
      preset:     @active_preset,
      severity:   @active_severity,
      start_date: @start_date&.to_s,
      end_date:   @end_date&.to_s
    }
  }
end
```

`@symptom_logs`, `@current_page`, and `@total_pages` are already set before the `respond_to` block, so they are available for both format branches.

## Acceptance Criteria

- [ ] `GET /symptom_logs` JSON returns envelope with `symptom_logs`, `current_page`, `total_pages`, `per_page`, `applied_filters`
- [ ] `applied_filters` includes `severity` key
- [ ] `symptom_logs_controller_test.rb` has tests asserting envelope keys (mirroring `peak_flow_readings_controller_test.rb` lines 302–312)

## Work Log

- 2026-03-08: Identified by agent-native-reviewer
