---
status: pending
priority: p2
issue_id: "296"
tags: [code-review, rails, api, agent-native, medications]
dependencies: []
---

# sick_day_dose_puffs missing from medication JSON response

## Problem Statement
The dashboard now shows a sick-day dose button when `active_illness` is set and `medication.sick_day_dose_puffs.present?`. An agent reading `GET /settings/medications.json` to decide how many puffs to log for a sick day cannot determine the sick-day dose value — `medication_json` includes `standard_dose_puffs` but omits `sick_day_dose_puffs`. The agent would have to hardcode or guess the sick-day count, breaking the principle that any UI action should be equally accessible to agents.

## Findings
**Flagged by:** agent-native-reviewer

**File:** `app/controllers/settings/medications_controller.rb`

`medication_json` includes `standard_dose_puffs` but not `sick_day_dose_puffs`. The field is already in `medication_params` and the Medication model — this is purely a serialization omission.

## Proposed Solutions

### Option A — Add sick_day_dose_puffs to medication_json (Recommended)
```ruby
def medication_json(med)
  med.as_json(only: %i[id name medication_type standard_dose_puffs sick_day_dose_puffs
                       doses_per_day starting_dose_count course starts_on ends_on created_at])
     .merge(remaining_doses: med.remaining_doses, low_stock: med.low_stock?, ...)
end
```
**Effort:** Trivial. **Risk:** None.

## Recommended Action

## Technical Details
- **File:** `app/controllers/settings/medications_controller.rb` — `medication_json`
- **Impact:** Agents cannot determine sick-day dose count without additional UI interaction

## Acceptance Criteria
- [ ] `medication_json` includes `sick_day_dose_puffs` field (nil when not set)
- [ ] Medications controller test asserts `sick_day_dose_puffs` is present in JSON response

## Work Log
- 2026-03-12: Code review finding — agent-native-reviewer

## Resources
- Branch: dev
