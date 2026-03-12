---
status: pending
priority: p2
issue_id: "297"
tags: [code-review, rails, security, authorization, defense-in-depth]
dependencies: []
---

# set_dose_log should scope from Current.user.dose_logs for defense-in-depth

## Problem Statement
`Settings::DoseLogsController#set_dose_log` finds the dose log as `@medication.dose_logs.find(params[:id])`. Authorization is correct today because `set_medication` scopes the medication to `Current.user.medications.find(...)` — a valid chain. However, the dose log authorization depends entirely on the medication scope being correct. If `set_medication` is ever weakened, bypassed, or a bug is introduced, no secondary check would catch cross-user dose log access. Defense-in-depth requires scoping from `Current.user` independently.

## Findings
**Flagged by:** security-sentinel (M-1)

**File:** `app/controllers/settings/dose_logs_controller.rb`

```ruby
def set_dose_log
  @dose_log = @medication.dose_logs.find(params[:id])
  # No direct Current.user scope — relies entirely on set_medication chain
end
```

The `DoseLog` model has a `user_id` column. Scoping from `Current.user.dose_logs` would make authorization self-evident.

## Proposed Solutions

### Option A — Scope from Current.user.dose_logs (Recommended)
```ruby
def set_dose_log
  @dose_log = Current.user.dose_logs.find(params[:id])
end
```
The `@medication` association is still available for context but authorization is independently enforced.
**Pros:** Self-evident authorization. Eliminates the transitive dependency. Matches the pattern used throughout the app (every `set_*` method scopes from `Current.user`).
**Effort:** Trivial. **Risk:** None.

## Recommended Action

## Technical Details
- **File:** `app/controllers/settings/dose_logs_controller.rb` — `set_dose_log`
- **Pattern:** All other `set_*` methods in the codebase scope from `Current.user.xxx.find(...)` directly

## Acceptance Criteria
- [ ] `set_dose_log` uses `Current.user.dose_logs.find(params[:id])` instead of `@medication.dose_logs.find(params[:id])`
- [ ] Existing cross-user isolation controller test still passes

## Work Log
- 2026-03-12: Code review finding — security-sentinel (M-1)

## Resources
- Branch: dev
