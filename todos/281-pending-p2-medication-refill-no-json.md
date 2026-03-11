---
status: pending
priority: p2
issue_id: "281"
tags: [code-review, rails, api, agent-native, medications]
dependencies: []
---

# `Settings::MedicationsController#refill` has no `format.json` branch

## Problem Statement

`PATCH /settings/medications/:id/refill` has no `respond_to` block at all — it responds only with Turbo Stream and HTML. An agent cannot refill a medication. Given that low-stock notifications are a key feature of the app, an agent answering "refill this medication" has no API path.

All other medication CRUD actions (`create`, `update`, `destroy`) have `format.json` branches.

## Findings

- **File:** `app/controllers/settings/medications_controller.rb` — `#refill` action
- **Agent:** agent-native-reviewer

## Proposed Solutions

### Option A — Add `format.json` to `#refill` (Recommended)

```ruby
respond_to do |format|
  format.turbo_stream
  format.html { redirect_to settings_medications_path, notice: flash.now[:notice] }
  format.json { render json: medication_json(@medication) }
end
```

The response should include the updated `starting_dose_count`, `remaining_doses`, `days_of_supply_remaining`, and `low_stock?`.

**Effort:** Small
**Risk:** Low

## Recommended Action

Option A. Follow the `#update` pattern.

## Technical Details

- **Affected file:** `app/controllers/settings/medications_controller.rb`

## Acceptance Criteria

- [ ] `PATCH /settings/medications/:id/refill.json` returns 200 with updated medication data
- [ ] Response includes `remaining_doses` and `days_of_supply_remaining`
- [ ] Controller test covers the JSON refill path

## Work Log

- 2026-03-11: Identified by agent-native-reviewer during code review of dev branch
