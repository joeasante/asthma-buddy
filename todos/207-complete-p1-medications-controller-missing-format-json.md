---
status: pending
priority: p1
issue_id: "207"
tags: [code-review, agent-native, api, json, medications]
dependencies: ["206"]
---

# `Settings::MedicationsController` Has No `format.json` — Agents Cannot Discover Medication IDs

## Problem Statement

`Settings::MedicationsController#index` and all other actions have no `format.json` branch. Even if Todo 206 (DoseLogsController JSON) is fixed, an agent trying to log a reliever dose still cannot resolve which `medication_id` to use because there is no `GET /settings/medications.json`. The `weekly_data` items in `/reliever-usage.json` do not include `medication_id` or medication name, so the agent has no way to connect "I need to log a dose for this medication" to a concrete ID.

This is a blocking dependency for the write-side agent parity introduced in Todo 206.

## Findings

**Flagged by:** agent-native-reviewer (P1)

**Location:** `app/controllers/settings/medications_controller.rb` — `index` action (lines 7–13) and all other actions (16–76)

No `format.json` on any action. `Accept: application/json` requests return 406.

## Proposed Solutions

### Option A — Add `format.json` to `index` first, then remaining actions (Recommended)
**Effort:** Small | **Risk:** Low

`index` is the minimum needed for agent discovery:

```ruby
def index
  @medications = Current.user.medications.chronological
  respond_to do |format|
    format.html
    format.json { render json: medications_json(@medications) }
  end
end

private

def medications_json(medications)
  medications.map do |med|
    {
      id:                   med.id,
      name:                 med.name,
      medication_type:      med.medication_type,
      standard_dose_puffs:  med.standard_dose_puffs,
      remaining_doses:      med.remaining_doses,
      low_stock:            med.low_stock?
    }
  end
end
```

Follow up with `format.json` on `create`, `update`, `destroy`, and `refill` in the same PR.

**Add tests:**
- `GET /settings/medications.json` → 200 with array of medications including `id` and `medication_type`
- Unauthenticated → 401

### Option B — Only fix `index` now
**Effort:** Smaller | **Risk:** Low — other actions can follow

Gets agent discovery working immediately. Mutation endpoints can follow.

## Recommended Action

Option A (both at once) if the PR for Todo 206 already touches this controller. Otherwise Option B to unblock agent discovery now.

## Technical Details

- **Affected files:** `app/controllers/settings/medications_controller.rb`, `test/controllers/settings/medications_controller_test.rb`
- **Blocked by:** None (can implement independently, though logically paired with Todo 206)
- **Blocks:** Todo 206 being fully useful to agents

## Acceptance Criteria

- [ ] `GET /settings/medications.json` returns 200 with array including `id`, `name`, `medication_type`
- [ ] Unauthenticated request returns 401
- [ ] Reliever medications are distinguishable by `medication_type: "reliever"` in the response
- [ ] Tests cover above cases

## Work Log

- 2026-03-10: Identified by agent-native-reviewer. Agent cannot resolve medication_id without this endpoint.

## Resources

- Precedent: `app/controllers/peak_flow_readings_controller.rb` (format.json pattern)
- Related: Todo 206 (DoseLogsController JSON write parity)
