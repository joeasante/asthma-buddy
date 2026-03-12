---
status: pending
priority: p3
issue_id: "299"
tags: [code-review, rails, cleanup, peak-flow]
dependencies: []
---

# duplicate_session_reading called twice in JSON create path

## Problem Statement
In `PeakFlowReadingsController#create`'s failure path, `@peak_flow_reading.duplicate_session_reading` is called three times: assigned to `@duplicate_reading` on line 139, then called again on line 145 for the presence check, and again on line 146 for serialization. Since it is an `attr_reader` (not a live query), there is no runtime cost. However, the repeated calls create a maintenance trap — if `duplicate_session_reading` is refactored to a live query, this silently becomes an N+1. Using `@duplicate_reading` consistently throughout is the correct pattern.

## Findings
**Flagged by:** kieran-rails-reviewer, security-sentinel (M-2), performance-oracle

**File:** `app/controllers/peak_flow_readings_controller.rb`

```ruby
@duplicate_reading = @peak_flow_reading.duplicate_session_reading  # assigned

if @peak_flow_reading.duplicate_session_reading.present?          # called again
  json_response[:duplicate_reading] = peak_flow_reading_json(@peak_flow_reading.duplicate_session_reading)  # called again
end
```

## Proposed Solutions
### Option A — Use the ivar throughout
```ruby
@duplicate_reading = @peak_flow_reading.duplicate_session_reading
if @duplicate_reading.present?
  json_response[:duplicate_reading] = peak_flow_reading_json(@duplicate_reading)
end
```
**Effort:** Trivial.

## Recommended Action

## Technical Details
- **File:** `app/controllers/peak_flow_readings_controller.rb` — `create` failure path

## Acceptance Criteria
- [ ] `@duplicate_reading` is used on all 3 references — no direct `duplicate_session_reading` calls after the initial assignment

## Work Log
- 2026-03-12: Code review finding — kieran-rails-reviewer, security-sentinel, performance-oracle

## Resources
- Branch: dev
