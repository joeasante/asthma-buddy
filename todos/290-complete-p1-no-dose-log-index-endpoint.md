---
status: pending
priority: p1
issue_id: "290"
tags: [code-review, rails, api, agent-native, dose-logs]
dependencies: []
---

# No dose log index endpoint — agent cannot list dose history for a medication

## Problem Statement
`Settings::DoseLogsController` has only `create` and `destroy` actions. There is no way for an agent (or any API consumer) to list dose logs for a given medication. An agent can log a dose and delete one by ID, but cannot answer "how many doses of medication X have I taken this week?" or "show me my dose history for this medication" without that data being embedded in another endpoint. The `GET /settings/medications.json` response does not include dose log history. This breaks agent-native parity — the UI shows a dose history panel that agents cannot read.

## Findings
**Flagged by:** agent-native-reviewer

**Location:** `app/controllers/settings/dose_logs_controller.rb` and `config/routes.rb`

Current routes:
```ruby
resources :dose_logs, only: %i[create destroy]
```

The medications settings page shows the 5 most recent dose logs per medication card. An agent has no equivalent read access.

## Proposed Solutions

### Option A — Add index action with JSON response (Recommended)
Add `index` to the dose_logs route and a minimal `index` action:
```ruby
# routes.rb
resources :dose_logs, only: %i[index create destroy]

# dose_logs_controller.rb
def index
  @dose_logs = @medication.dose_logs.chronological.limit(20)
  respond_to do |format|
    format.json { render json: @dose_logs.map { |dl| dose_log_json(dl) } }
  end
end
```
Support optional `since` / `before` date params for filtering.
**Pros:** Closes agent-native parity gap. Minimal surface area (JSON only, no HTML template needed). Scoped via `set_medication` before_action so authorization is already handled.
**Cons:** Increases public surface area.
**Effort:** Small. **Risk:** Low.

### Option B — Include recent dose logs in the medication JSON response
Embed `recent_dose_logs` array inside `medication_json`:
```ruby
recent_dose_logs: med.dose_logs.chronological.limit(10).map { |dl| dose_log_json(dl) }
```
**Pros:** No new route or action needed. Agents get dose history as part of the medication read.
**Cons:** Increases medication response payload even when dose history is not needed. Tight coupling.
**Effort:** Small. **Risk:** Low.

## Recommended Action

## Technical Details
- **Files:** `app/controllers/settings/dose_logs_controller.rb`, `config/routes.rb`
- **Authorization:** `set_medication` before_action already scopes to `Current.user.medications.find(params[:medication_id])`, so `@medication.dose_logs` is already user-scoped
- **Impact:** Agents cannot read dose history — one of the core medication tracking features is write-only from the API perspective

## Acceptance Criteria
- [ ] `GET /settings/medications/:medication_id/dose_logs.json` returns an array of dose log objects
- [ ] Response includes `id`, `puffs`, `recorded_at` per log entry
- [ ] Supports optional `since` date param for range filtering
- [ ] Cross-user isolation: a user cannot access another user's medication's dose logs
- [ ] Controller test added for the index action (success, scoping, unauthenticated redirect)

## Work Log
- 2026-03-12: Identified in code review — agent-native-reviewer flagged as critical parity gap

## Resources
- Branch: dev
- File: app/controllers/settings/dose_logs_controller.rb
