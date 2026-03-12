---
title: "Authorization scope bypass: using Current.user.x instead of @parent.x in nested resource controllers"
problem_type: security-issue
component: "Settings::DoseLogsController#set_dose_log, nested resource authorization"
tags: [authorization, access-control, scope, nested-resources, dose-logs, before-action]
symptoms:
  - Users can access or destroy records belonging to a sibling resource (different medication, same user)
  - Cross-resource access returns 200 instead of 404
  - Before-action chain sets a parent scope (@medication) that downstream queries silently ignore
root_cause: "set_dose_log used Current.user.dose_logs.find(params[:id]) instead of @medication.dose_logs.find(params[:id]). Even though @medication was already user-scoped via set_medication, the dose log lookup bypassed that parent scope entirely, allowing any of the user's dose logs to be found regardless of medication context."
---

# Authorization Scope Bypass via Wrong Parent Association in Nested Resource Controller

## Problem

`Settings::DoseLogsController` is a nested resource under `Settings::MedicationsController`. The route is:

```
DELETE /settings/medications/:medication_id/dose_logs/:id
```

The controller has two `before_action` callbacks that run in order:

```ruby
before_action :set_medication              # sets @medication to the user's medication
before_action :set_dose_log, only: :destroy  # should scope to that medication
```

But `set_dose_log` was implemented using `Current.user.dose_logs.find` instead of `@medication.dose_logs.find`:

```ruby
# BEFORE — bypasses the @medication scope
def set_dose_log
  @dose_log = Current.user.dose_logs.find(params[:id])
end
```

This means a user could craft a `DELETE` request with any valid `dose_log` ID they own — regardless of which `medication_id` was in the URL. The `@medication` guard set by `set_medication` was completely ignored in the lookup.

### Scope of the vulnerability

In the current single-user-per-account data model, this allows:
- A user to delete their own dose logs via the wrong medication URL (e.g. logging shows under Inhaler A but deletes from Inhaler B)
- Cross-medication dose log destruction — records can be removed without the UI updating the correct medication's count

In a future multi-user or shared-account model, the scope of risk increases significantly.

## Root Cause

```ruby
# set_medication (correct — scoped to current user):
def set_medication
  @medication = Current.user.medications.find(params[:medication_id])
end

# set_dose_log (wrong — ignores the @medication scope):
def set_dose_log
  @dose_log = Current.user.dose_logs.find(params[:id])
  #           ^^^^^^^^^^^^^^^^^ should be @medication.dose_logs
end
```

`Current.user.dose_logs` finds ANY dose log owned by the user. `@medication.dose_logs` finds only dose logs belonging to `@medication` — which is already user-scoped because `set_medication` uses `Current.user.medications`.

## Solution

```ruby
# AFTER — scoped through the parent, which is already user-scoped
def set_dose_log
  @dose_log = @medication.dose_logs.find(params[:id])
end
```

`@medication` is guaranteed to belong to `Current.user` (set by the preceding `set_medication` before_action), so this lookup is both user-safe and medication-scoped. A dose log from a different medication raises `ActiveRecord::RecordNotFound` (→ 404).

## Prevention

### Rule of thumb for nested resource controllers

**Never use `Current.user.x.find` in a nested controller when a parent `@resource` is already set by a before_action.**

Always chain through the parent:

```ruby
# Correct pattern for nested resources
class Settings::DoseLogsController < Settings::BaseController
  before_action :set_medication             # scopes to current user's medication
  before_action :set_dose_log, only: :destroy  # scopes to that medication's dose logs

  private

  def set_medication
    @medication = Current.user.medications.find(params[:medication_id])
  end

  def set_dose_log
    @dose_log = @medication.dose_logs.find(params[:id])  # ← always chain through parent
  end
end
```

This ensures the database enforces both the user boundary AND the parent-child relationship, not just one of them.

### Code review checklist for nested resource controllers

1. **Find the before_action chain** — list every `before_action` that sets an instance variable
2. **Trace all `.find` calls** — verify they use the most recently set parent scope, not `Current.user` directly
3. **Check routes** — if `resources :dose_logs` is nested inside `resources :medications`, the controller must scope through `@medication`
4. **Common anti-patterns to flag:**
   - `Current.user.x.find` in a controller with a parent `before_action`
   - `params[:id]` used in a find that doesn't go through the parent association
   - A `set_x` method that ignores the `@parent` set two lines above it

### Test pattern

```ruby
# Test: cross-medication dose log access returns 404
test "cannot destroy dose log via a different medication" do
  med_a = Current.user.medications.create!(name: "Inhaler A", ...)
  med_b = Current.user.medications.create!(name: "Inhaler B", ...)
  dose_on_a = med_a.dose_logs.create!(puffs: 2, recorded_at: Time.current, user: @user)

  # Try to delete dose_on_a by routing through med_b's URL
  assert_no_difference "DoseLog.count" do
    delete settings_medication_dose_log_url(med_b, dose_on_a)
  end

  assert_response :not_found
end

# Test: dose log from another user is not accessible
test "cannot destroy another user's dose log" do
  other_user = create_user
  other_med  = other_user.medications.create!(name: "Other Inhaler", ...)
  other_dose = other_med.dose_logs.create!(puffs: 2, recorded_at: Time.current, user: other_user)

  # Our medication route, but someone else's dose log ID
  assert_no_difference "DoseLog.count" do
    delete settings_medication_dose_log_url(@medication, other_dose)
  end

  assert_response :not_found
end
```

## Generalisation

This class of bug appears in any nested resource controller. Common examples:

| Route | Wrong | Correct |
|---|---|---|
| `/projects/:project_id/tasks/:id` | `Current.user.tasks.find(id)` | `@project.tasks.find(id)` |
| `/medications/:med_id/dose_logs/:id` | `Current.user.dose_logs.find(id)` | `@medication.dose_logs.find(id)` |
| `/teams/:team_id/members/:id` | `Member.find(id)` | `@team.members.find(id)` |

The fix is always the same: chain through the most-specific already-verified parent.

## Related

- `app/controllers/settings/dose_logs_controller.rb` — the fixed controller
- `config/routes.rb` — nested `resources :dose_logs` inside `resources :medications`
- `app/controllers/settings/base_controller.rb` — `Settings::BaseController` pattern
- Rails Guides: Nested Resources, `before_action` with `:only`
