---
status: pending
priority: p1
issue_id: "064"
tags: [code-review, agent-native, api, rails]
dependencies: []
---

# Missing `format.json` on `SettingsController` — Agents Cannot Set or Read Personal Best

## Problem Statement

Both `SettingsController#show` and `SettingsController#update_personal_best` lack JSON support. An agent cannot read the current personal best or update it programmatically. This is doubly impactful: personal best is the reference value that gives every peak flow reading its clinical meaning. Without it, zone classification is `nil`.

Without this endpoint, an agent onboarding a new user (or updating personal best after a clinic visit) cannot complete the minimum setup required for the app to produce useful zone feedback.

## Findings

**Flagged by:** agent-native-reviewer, pattern-recognition-specialist

**Location:** `app/controllers/settings_controller.rb:3-26`

```ruby
def show
  # No respond_to block — HTML only
  @current_personal_best = PersonalBestRecord.current_for(Current.user)
  @personal_best_record = Current.user.personal_best_records.new(recorded_at: Time.current)
end

def update_personal_best
  @personal_best_record = Current.user.personal_best_records.new(personal_best_params)
  if @personal_best_record.save
    redirect_to settings_path, notice: "..."  # redirect — useless for JSON clients
  else
    render :show, status: :unprocessable_entity  # HTML only
  end
end
```

**Dependency:** An agent cannot complete the "log a reading and see zone feedback" workflow without first being able to set a personal best. Issues 063 and 064 are a pair.

## Proposed Solutions

### Option A: Add format.json to both actions (Recommended)

```ruby
def show
  @current_personal_best = PersonalBestRecord.current_for(Current.user)
  @personal_best_record = Current.user.personal_best_records.new(recorded_at: Time.current)
  respond_to do |format|
    format.html
    format.json do
      render json: {
        current_personal_best: @current_personal_best ? {
          id: @current_personal_best.id,
          value: @current_personal_best.value,
          recorded_at: @current_personal_best.recorded_at
        } : nil,
        valid_range: { min: 100, max: 900 }
      }
    end
  end
end

def update_personal_best
  @personal_best_record = Current.user.personal_best_records.new(personal_best_params)
  if @personal_best_record.save
    respond_to do |format|
      format.html { redirect_to settings_path, notice: "..." }
      format.json do
        render json: {
          id: @personal_best_record.id,
          value: @personal_best_record.value,
          recorded_at: @personal_best_record.recorded_at
        }, status: :created
      end
    end
  else
    @current_personal_best = PersonalBestRecord.current_for(Current.user)
    respond_to do |format|
      format.html { render :show, status: :unprocessable_entity }
      format.json { render json: { errors: @personal_best_record.errors.full_messages }, status: :unprocessable_entity }
    end
  end
end
```

**Pros:** Complete agent access to settings, includes `valid_range` metadata so agents know constraints
**Cons:** None
**Effort:** Small
**Risk:** Low

### Option B: Separate `PersonalBestRecordsController` resource

Expose `/personal-best-records` as a REST resource separate from the settings UI. The settings page would POST to the same endpoint.

**Pros:** Cleaner REST design, easier to add history endpoint later
**Cons:** Requires route refactor; HTML form targets would change; more files
**Effort:** Medium
**Risk:** Low-Medium

## Recommended Action

Option A for now. Revisit as Option B if settings grows beyond personal best (Phase 7+).

## Technical Details

**Affected files:**
- `app/controllers/settings_controller.rb`
- `test/controllers/settings_controller_test.rb` (add JSON test cases)

**Test cases to add:**
- GET /settings with `as: :json` returns current personal best (or null if none)
- POST /settings/personal_best with `as: :json` + valid value returns 201
- POST /settings/personal_best with `as: :json` + invalid value returns 422 with errors
- Unauthenticated JSON requests return 401

## Acceptance Criteria

- [ ] `GET /settings` responds with JSON containing `current_personal_best` (or null) and `valid_range`
- [ ] `POST /settings/personal_best` responds with JSON on success (201)
- [ ] `POST /settings/personal_best` responds with JSON errors on failure (422)
- [ ] Unauthenticated requests return 401 JSON (covered by concern, needs test)
- [ ] Controller tests cover all JSON scenarios

## Work Log

- 2026-03-07: Identified by agent-native-reviewer and pattern-recognition-specialist during Phase 6 code review

## Resources

- Reference implementation: `app/controllers/symptom_logs_controller.rb`
- App contract: `app/controllers/application_controller.rb:16`
