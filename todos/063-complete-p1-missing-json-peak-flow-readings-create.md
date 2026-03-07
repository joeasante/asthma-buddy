---
status: pending
priority: p1
issue_id: "063"
tags: [code-review, agent-native, api, rails]
dependencies: []
---

# Missing `format.json` on `PeakFlowReadingsController#create` — Violates App's Architectural Contract

## Problem Statement

`PeakFlowReadingsController#create` handles only `format.turbo_stream` and `format.html`. There is no `format.json` branch. `ApplicationController` has an explicit written rule requiring `format.json` on every action that creates or modifies data. This is a direct violation of the app's own architectural contract.

Peak flow recording is the primary clinical action of the app. An agent that cannot log a reading cannot participate in the most important workflow Phase 6 was built for.

## Findings

**Flagged by:** agent-native-reviewer, pattern-recognition-specialist, kieran-rails-reviewer

**Location:** `app/controllers/peak_flow_readings_controller.rb:18-36`

```ruby
def create
  @peak_flow_reading = Current.user.peak_flow_readings.new(peak_flow_reading_params)
  if @peak_flow_reading.save
    @flash_message = zone_flash_message(@peak_flow_reading)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to new_peak_flow_reading_path, notice: @flash_message }
      # format.json — MISSING
    end
  else
    respond_to do |format|
      format.turbo_stream { ... }
      format.html { render :new, status: :unprocessable_entity }
      # format.json — MISSING
    end
  end
end
```

**ApplicationController contract (line 16):**
> "Every resource action that creates/modifies data must support `format.json` so agents can call endpoints programmatically."

**Symptom logs reference implementation:** `SymptomLogsController#create` correctly implements `format.json` on both success and failure paths.

**Additional concern:** `zone` is stored as an integer enum. A naive `as_json` dump returns `0`, `1`, `2` — not `"green"`, `"yellow"`, `"red"`. The JSON response must use the string accessor and include derived fields (`zone_percentage`, `personal_best_at_reading_time`) that give the response clinical meaning.

## Proposed Solutions

### Option A: Add format.json using a private serializer helper (Recommended)

Follow the `SymptomLogsController` pattern — add a `peak_flow_reading_json` private helper and add `format.json` to both branches:

```ruby
def create
  @peak_flow_reading = Current.user.peak_flow_readings.new(peak_flow_reading_params)
  if @peak_flow_reading.save
    @flash_message = zone_flash_message(@peak_flow_reading)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to new_peak_flow_reading_path, notice: @flash_message }
      format.json { render json: peak_flow_reading_json(@peak_flow_reading), status: :created }
    end
  else
    @has_personal_best = PersonalBestRecord.current_for(Current.user).present?
    respond_to do |format|
      format.turbo_stream { ... }
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: { errors: @peak_flow_reading.errors.full_messages }, status: :unprocessable_entity }
    end
  end
end

private

def peak_flow_reading_json(reading)
  pb = reading.personal_best_at_reading_time
  percentage = pb ? ((reading.value.to_f / pb) * 100).round : nil
  {
    id: reading.id,
    value: reading.value,
    recorded_at: reading.recorded_at,
    zone: reading.zone,          # string: "green", "yellow", "red", or nil
    zone_percentage: percentage,
    personal_best_at_reading_time: pb,
    created_at: reading.created_at
  }
end
```

**Pros:** Follows established pattern, exposes clinically meaningful derived fields, explicit serialization avoids enum integer leak
**Cons:** None — this is the correct pattern
**Effort:** Small
**Risk:** Low

### Option B: Use ActiveModel::Serializer or jbuilder

Extract JSON rendering to a serializer or view template.

**Pros:** More maintainable at scale
**Cons:** Overkill for a small app; adds a gem dependency or extra file; inconsistent with how symptom_logs does it
**Effort:** Medium
**Risk:** Low

## Recommended Action

Option A.

## Technical Details

**Affected files:**
- `app/controllers/peak_flow_readings_controller.rb`
- `test/controllers/peak_flow_readings_controller_test.rb` (add JSON test cases)

**Test cases to add:**
- POST /peak-flow-readings with `as: :json` returns 201 with zone string
- POST /peak-flow-readings with invalid params + `as: :json` returns 422 with errors array
- DELETE /session then POST /peak-flow-readings with `as: :json` returns 401

## Acceptance Criteria

- [ ] `format.json` added to `create` success path (201, JSON body with zone as string)
- [ ] `format.json` added to `create` failure path (422, errors array)
- [ ] JSON response includes `zone` as string (not integer)
- [ ] JSON response includes `zone_percentage` and `personal_best_at_reading_time`
- [ ] Unauthenticated JSON request returns 401 (handled by concern, just needs a test)
- [ ] Controller tests cover all three JSON scenarios

## Work Log

- 2026-03-07: Identified by agent-native-reviewer, pattern-recognition-specialist, and kieran-rails-reviewer during Phase 6 code review

## Resources

- Reference implementation: `app/controllers/symptom_logs_controller.rb`
- App contract: `app/controllers/application_controller.rb:16`
