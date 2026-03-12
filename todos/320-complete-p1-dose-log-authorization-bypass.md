---
status: complete
priority: p1
issue_id: "320"
tags: [code-review, security, authorization, dose-logs]
dependencies: []
---

# `DoseLogsController#set_dose_log` Authorization Bypass

## Problem Statement

`app/controllers/settings/dose_logs_controller.rb` uses `Current.user.dose_logs.find(params[:id])` in `set_dose_log` instead of `@medication.dose_logs.find(params[:id])`. This means a logged-in user can access, view, or destroy any dose log belonging to any of their own medications — including medications they've been scoped away from. More critically, the before-action chain sets `@medication` via `set_medication` first, but `set_dose_log` ignores that scope entirely. Any user could craft a request with a valid `dose_log` id that belongs to a different medication and successfully destroy it.

In the current schema this primarily affects cross-medication access within the same user account, but as the model evolves (shared accounts, household members) this breaks the authorization boundary completely.

## Findings

**Flagged by:** kieran-rails-reviewer (rated CRITICAL)

```ruby
# app/controllers/settings/dose_logs_controller.rb:61
def set_dose_log
  @dose_log = Current.user.dose_logs.find(params[:id])  # BUG: ignores @medication scope
end
```

The correct implementation:
```ruby
def set_dose_log
  @dose_log = @medication.dose_logs.find(params[:id])  # scoped to the medication
end
```

`@medication` is always set before `set_dose_log` fires (both are before_action callbacks), so the scoped version is safe.

## Proposed Solutions

### Option A: Scope to `@medication` (Recommended)
Change `Current.user.dose_logs.find` to `@medication.dose_logs.find`.

**Pros:** Correct authorization — a dose log can only be found if it belongs to the current medication
**Cons:** None
**Effort:** Small (1 line)
**Risk:** Low

### Option B: Add explicit user cross-check
Scope through both: `@medication.dose_logs.where(id: params[:id]).first!` with manual user ownership check.

**Pros:** Belt-and-suspenders
**Cons:** Redundant — `@medication` is already user-scoped via `set_medication`
**Effort:** Small
**Risk:** Low

### Recommended Action

Option A.

## Technical Details

- **File:** `app/controllers/settings/dose_logs_controller.rb`, `set_dose_log` method (~line 61)
- `set_medication` already scopes to `Current.user.medications`, so `@medication.dose_logs` is properly user-scoped

## Acceptance Criteria

- [ ] `set_dose_log` uses `@medication.dose_logs.find(params[:id])`
- [ ] Attempting to destroy a dose log from a different medication returns 404
- [ ] Existing dose log tests pass
- [ ] Add test: cross-medication dose log access returns 404

## Work Log

- 2026-03-12: Created from Milestone 2 code review — kieran-rails-reviewer CRITICAL finding
