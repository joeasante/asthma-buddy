---
status: pending
priority: p3
issue_id: "104"
tags: [code-review, testing, rails, peak-flow, api]
dependencies: ["091", "092", "100"]
---

# Missing JSON tests for `update`, `destroy`, and paginated `index` — coverage gap

## Problem Statement

The controller test file has thorough JSON coverage for `create` but no JSON assertions for `update`, `destroy`, or the `index` pagination envelope. Once todos 091, 092, and 100 are implemented, corresponding tests must exist to prevent regressions.

## Findings

**Flagged by:** agent-native-reviewer (P3)

**Location:** `test/controllers/peak_flow_readings_controller_test.rb`

Currently missing:
- `update` with `Accept: application/json` → 200 + reading body
- `update` with invalid params + JSON → 422 + errors
- `destroy` with `Accept: application/json` → 204
- `index` with JSON → asserts envelope keys `readings`, `current_page`, `total_pages`

## Proposed Solutions

### Option A: Append tests to existing controller test file

```ruby
# JSON update
test "update with valid params returns JSON reading" do
  reading = peak_flow_readings(:alice_green_reading)
  patch peak_flow_reading_path(reading),
        params: { peak_flow_reading: { value: 420, recorded_at: reading.recorded_at.iso8601 } },
        headers: { "Accept" => "application/json" }
  assert_response :success
  assert_equal "application/json", response.media_type
  body = JSON.parse(response.body)
  assert_equal 420, body["value"]
end

test "update with blank value returns 422 JSON" do
  reading = peak_flow_readings(:alice_green_reading)
  patch peak_flow_reading_path(reading),
        params: { peak_flow_reading: { value: "", recorded_at: reading.recorded_at.iso8601 } },
        headers: { "Accept" => "application/json" }
  assert_response :unprocessable_entity
  assert JSON.parse(response.body)["errors"].present?
end

test "destroy returns 204 JSON" do
  reading = peak_flow_readings(:alice_green_reading)
  assert_difference "PeakFlowReading.count", -1 do
    delete peak_flow_reading_path(reading), headers: { "Accept" => "application/json" }
  end
  assert_response :no_content
end

test "index JSON includes pagination envelope" do
  get peak_flow_readings_path, headers: { "Accept" => "application/json" }
  body = JSON.parse(response.body)
  assert body.key?("readings")
  assert body.key?("current_page")
  assert body.key?("total_pages")
end
```

- **Effort:** Small
- **Risk:** None

## Recommended Action

Add after todos 091, 092, 100 are complete.

## Technical Details

- **Affected files:** `test/controllers/peak_flow_readings_controller_test.rb`
- **Blocked by:** 091, 092, 100

## Acceptance Criteria

- [ ] JSON update (success) test passes
- [ ] JSON update (failure) test passes
- [ ] JSON destroy test passes
- [ ] JSON index envelope test passes

## Work Log

- 2026-03-07: Identified during Phase 7 code review
