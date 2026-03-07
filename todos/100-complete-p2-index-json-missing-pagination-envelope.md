---
status: pending
priority: p2
issue_id: "100"
tags: [code-review, agent-native, api, rails, peak-flow, pagination]
dependencies: []
---

# `index` JSON response is a bare array — no pagination metadata for agent/API consumers

## Problem Statement

`GET /peak-flow-readings.json` returns a bare array of readings. An agent cannot determine how many pages exist, what the current page is, or whether there are more readings to fetch. `@current_page` and `@total_pages` are already computed in the controller but never included in the JSON response.

## Findings

**Flagged by:** agent-native-reviewer (P2)

**Location:** `app/controllers/peak_flow_readings_controller.rb:57-61`

```ruby
format.json { render json: @peak_flow_readings.map { |r| peak_flow_reading_json(r) } }
```

An agent paginating this endpoint must blindly increment `?page=` until it gets fewer than 25 results — it has no way to know the total.

## Proposed Solutions

### Option A: Wrap in an envelope object with pagination metadata (Recommended)

```ruby
format.json do
  render json: {
    readings: @peak_flow_readings.map { |r| peak_flow_reading_json(r) },
    current_page: @current_page,
    total_pages: @total_pages,
    per_page: 25,
    applied_filters: {
      preset: @active_preset,
      start_date: @start_date&.to_s,
      end_date: @end_date&.to_s
    }
  }
end
```

- **Pros:** Standard API envelope; agents can paginate correctly; filters are discoverable
- **Effort:** Small
- **Risk:** Breaking change for any existing JSON consumer (currently none documented)

### Option B: Add Link headers (RFC 5988)

Return `Link: <...?page=2>; rel="next"` headers. Used by GitHub API.

- **Pros:** Standard, header-based
- **Cons:** Harder for agents to parse than JSON; more complex
- **Effort:** Medium

## Recommended Action

Option A — JSON envelope. Consistent with REST API conventions and easiest for programmatic clients.

## Technical Details

- **Affected files:** `app/controllers/peak_flow_readings_controller.rb`

## Acceptance Criteria

- [ ] `GET /peak-flow-readings.json` returns `{ readings: [...], current_page: N, total_pages: N, per_page: 25, applied_filters: {...} }`
- [ ] An agent can paginate all readings by incrementing `?page=` until `current_page == total_pages`
- [ ] Add controller test asserting envelope keys are present in JSON response

## Work Log

- 2026-03-07: Identified during Phase 7 code review
