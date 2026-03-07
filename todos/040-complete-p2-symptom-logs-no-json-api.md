---
status: complete
priority: p2
issue_id: "040"
tags: [code-review, agent-native, api, json, symptom-logs]
dependencies: ["033"]
---

# `SymptomLogsController` Has No JSON API — Core Health Data Inaccessible to Agents

## Problem Statement

`SymptomLogsController` handles all CRUD operations for symptom logs but every action uses only `format.turbo_stream` and `format.html`. There is no `format.json` response for any action. This means agents cannot read a user's symptom history, log a new symptom, update an entry, or delete a record — the entire health-tracking purpose of the application is inaccessible to agents, violating the stated policy in `ApplicationController` that every data action must support JSON.

## Findings

**Flagged by:** agent-native-reviewer (Critical Issue 3)

**Location:** `app/controllers/symptom_logs_controller.rb` — all actions

**Missing JSON coverage:**
- `GET /symptom_logs` — no JSON collection representation
- `POST /symptom_logs` — no JSON create response
- `PATCH /symptom_logs/:id` — no JSON update response
- `DELETE /symptom_logs/:id` — no JSON delete response

**Additional index concern:** The `index` action initializes a new `SymptomLog` for the form (`@symptom_log = Current.user.symptom_logs.new(...)`) and loads all entries without pagination. A JSON API consumer needs only the collection.

## Proposed Solutions

### Solution A: Add `format.json` to each action inline (Recommended for now)
```ruby
def index
  @symptom_logs = Current.user.symptom_logs.chronological.includes(:rich_text_notes)
  @symptom_log = Current.user.symptom_logs.new(recorded_at: Time.current)

  respond_to do |format|
    format.html
    format.json { render json: @symptom_logs.as_json(only: [:id, :symptom_type, :severity, :recorded_at], methods: [:notes]) }
  end
end

def create
  @symptom_log = Current.user.symptom_logs.new(symptom_log_params)
  if @symptom_log.save
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to symptom_logs_path }
      format.json { render json: @symptom_log.as_json(only: [:id, :symptom_type, :severity, :recorded_at]), status: :created }
    end
  else
    respond_to do |format|
      format.turbo_stream
      format.html { render :index, status: :unprocessable_entity }
      format.json { render json: { errors: @symptom_log.errors.full_messages }, status: :unprocessable_entity }
    end
  end
end
```
- **Effort:** Medium (all 5 actions)
- **Risk:** Low (additive)

### Solution B: Jbuilder views
Create `app/views/symptom_logs/index.json.jbuilder`, `show.json.jbuilder` etc. per the project's stated preference. Cleaner long-term.
- **Effort:** Medium
- **Risk:** Low

## Recommended Action

Solution A for speed, Solution B for long-term cleanliness. Depends on todo #033 (`request_authentication` JSON 401) being in place first so authenticated API access works end-to-end.

## Technical Details

- **File:** `app/controllers/symptom_logs_controller.rb`
- **Note:** The `SymptomLog` model uses `has_rich_text :notes` — the `notes` field requires special handling in JSON output (ActionText doesn't auto-serialize to JSON). Use `symptom_log.notes.to_plain_text` or `symptom_log.notes.body.to_s` for JSON.

## Acceptance Criteria

- [ ] `GET /symptom_logs.json` returns authenticated user's logs as JSON array
- [ ] `POST /symptom_logs` with `as: :json` and valid params returns `201` with created log
- [ ] `POST /symptom_logs` with `as: :json` and invalid params returns `422 { errors: [...] }`
- [ ] `PATCH /symptom_logs/:id` with `as: :json` returns `200` with updated log
- [ ] `DELETE /symptom_logs/:id` with `as: :json` returns `204`
- [ ] All JSON endpoints scope data to `Current.user` (no IDOR)
- [ ] Controller tests for JSON paths exist

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by agent-native-reviewer as Critical Issue 3.
