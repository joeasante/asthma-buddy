---
status: pending
priority: p1
issue_id: "076"
tags: [code-review, agent-native, api, rails]
dependencies: []
---

# Missing `GET /peak-flow-readings` Index Endpoint — Agent Cannot Read History

## Problem Statement

`PeakFlowReadingsController` only exposes `new` and `create`. An agent can record a reading and receive zone data in the `201` response, but has no programmatic way to subsequently read the user's reading history. This blocks any agentic workflow that needs trend analysis, zone pattern detection, or context gathering before making recommendations (e.g. "your last 3 readings were all Yellow Zone — have you reviewed your medication plan?").

The `POST /peak-flow-readings` response returns an `id`, but without a `show` or `index` endpoint that `id` is opaque — an agent cannot fetch it later.

By contrast, `SymptomLogsController` has a full `index` action with date-range filtering and JSON support, which is the established pattern.

## Findings

**Flagged by:** agent-native-reviewer (P1)

**Current routes** — `config/routes.rb:10`:

```ruby
resources :peak_flow_readings, path: "peak-flow-readings", only: %i[ new create ]
```

**Existing infrastructure that makes this easy to add:**
- Compound index `(user_id, recorded_at)` already on `peak_flow_readings` — index covers the needed query
- `chronological` scope already on `PeakFlowReading`
- `peak_flow_reading_json` serializer already in controller
- `SymptomLogsController#index` provides the exact pattern to follow (date range filtering, format.json)

## Proposed Solutions

### Option A: Add index with date-range filtering (Recommended)
**Effort:** Medium | **Risk:** Low

Follow `SymptomLogsController#index` pattern:

```ruby
# config/routes.rb
resources :peak_flow_readings, path: "peak-flow-readings", only: %i[ new create index ]

# app/controllers/peak_flow_readings_controller.rb
def index
  start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
  end_date   = params[:end_date].present?   ? Date.parse(params[:end_date])   : Date.current

  @peak_flow_readings = Current.user.peak_flow_readings
    .chronological
    .where(recorded_at: start_date.beginning_of_day..end_date.end_of_day)

  respond_to do |format|
    format.html
    format.json { render json: @peak_flow_readings.map { |r| peak_flow_reading_json(r) } }
  end
end
```

Parameters: `start_date` (ISO date, default: 30 days ago), `end_date` (ISO date, default: today).

### Option B: Add index (JSON only, no HTML view)
**Effort:** Small | **Risk:** Low

If there is no current plan for a history HTML page, respond to JSON only:

```ruby
def index
  respond_to do |format|
    format.json do
      readings = Current.user.peak_flow_readings.chronological.limit(100)
      render json: readings.map { |r| peak_flow_reading_json(r) }
    end
  end
end
```

Simple but no date filtering and doesn't provide an HTML page for users.

### Option C: Add both index and show
**Effort:** Medium | **Risk:** Low

Add `show` alongside `index` so the `id` returned by `create` is actionable. The `show` is a single additional route with minimal implementation.

## Recommended Action

Option A — full `index` with date-range filtering. Matches the `SymptomLogsController` precedent, gives agents the filtering capability needed for trend analysis, and provides the HTML hook for a future history page.

## Technical Details

**Affected files:**
- `config/routes.rb`
- `app/controllers/peak_flow_readings_controller.rb`
- `app/views/peak_flow_readings/index.html.erb` (if adding HTML view)
- `test/controllers/peak_flow_readings_controller_test.rb`

## Acceptance Criteria

- [ ] `GET /peak-flow-readings` returns 200 JSON array of readings for authenticated user
- [ ] Response includes `id`, `value`, `recorded_at`, `zone`, `zone_percentage` per reading
- [ ] Date filtering works via `?start_date=&end_date=`
- [ ] Unauthenticated request returns 401 JSON
- [ ] One user cannot see another user's readings
- [ ] `bin/rails test` passes with 0 failures

## Work Log

- 2026-03-07: Identified by agent-native-reviewer in Phase 6 code review
