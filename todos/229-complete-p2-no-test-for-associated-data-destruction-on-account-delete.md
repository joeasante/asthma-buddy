---
status: pending
priority: p2
issue_id: "229"
tags: [testing, rails, code-review, data-integrity]
dependencies: []
---

# AccountsController Tests Assert User.count Decrements but Don't Verify Associated Health Data Is Destroyed

## Problem Statement

The controller test asserts `assert_difference "User.count", -1` but does not verify that dependent associations (`symptom_logs`, `peak_flow_readings`, `medications`, `dose_logs`, `health_events`) are actually destroyed. The controller's own notice text names these associations explicitly: "symptom logs, peak flow readings, medications, dose logs, and health events".

A future regression — removing `dependent: :destroy` from a model association, adding a new association without the option, or a scope misconfiguration — would leave orphaned PHI (Protected Health Information) in the database. The test suite would still pass because it only checks `User.count`. The orphaned data would be invisible until a database audit.

## Findings

**Flagged by:** kieran-rails-reviewer

**Location:** `test/controllers/accounts_controller_test.rb` line 9

**Current setup:** `@user = users(:verified_user)` — the fixture user is used directly without seeding associated health records. Even if `dependent: :destroy` were removed from every model, the test would still pass because there are no associated records to destroy.

## Proposed Solutions

### Option A — Controller Test with Cascade Verification (Recommended)

Extend the existing destroy test or add a new test that:

1. Creates at least one record per association type for `@user`
2. Calls `DELETE /account` with `confirmation: "DELETE"`
3. Asserts all associated records are gone

```ruby
test "destroy deletes all associated health data" do
  symptom_log   = SymptomLog.create!(user: @user, logged_at: Time.current, severity: 1)
  peak_flow     = PeakFlowReading.create!(user: @user, value: 400, measured_at: Time.current)
  medication    = Medication.create!(user: @user, name: "Ventolin", dosage: "100mcg")
  dose_log      = DoseLog.create!(medication: medication, taken_at: Time.current)
  health_event  = HealthEvent.create!(user: @user, event_type: "trigger", occurred_at: Time.current)

  delete account_url, params: { confirmation: "DELETE" }

  assert_equal 0, SymptomLog.where(user_id: @user.id).count,    "SymptomLogs not destroyed"
  assert_equal 0, PeakFlowReading.where(user_id: @user.id).count, "PeakFlowReadings not destroyed"
  assert_equal 0, Medication.where(user_id: @user.id).count,    "Medications not destroyed"
  assert_equal 0, DoseLog.where(id: dose_log.id).count,         "DoseLogs not destroyed"
  assert_equal 0, HealthEvent.where(user_id: @user.id).count,   "HealthEvents not destroyed"
end
```

**Pros:** Directly tests the cascade at the integration level; will catch any regression in `dependent:` configuration or newly added associations missing the option.
**Cons:** Requires knowing the minimum valid attributes for each model — may need fixture data or factory helpers.
**Effort:** Small–Medium
**Risk:** None

### Option B — Model-Level Cascade Test in user_test.rb

Add tests to `test/models/user_test.rb` verifying that `user.destroy` cascades to each association:

```ruby
test "destroying user destroys associated symptom logs" do
  user = users(:verified_user)
  SymptomLog.create!(user: user, ...)
  user.destroy
  assert_equal 0, SymptomLog.where(user_id: user.id).count
end
```

**Pros:** Tests the model contract independent of the HTTP layer; faster to run.
**Cons:** Does not cover the full controller flow (confirmation check, flash, redirect); if the controller bypasses `user.destroy` the test would not catch it.
**Effort:** Small
**Risk:** None

## Recommended Action

Option A. Testing the cascade at the controller level is more valuable because it exercises the full destroy path actually triggered in production. Option B can be added as a complement but should not replace the controller-level assertion.

## Technical Details

**Affected files:**
- `test/controllers/accounts_controller_test.rb`

**Acceptance Criteria:**
- [ ] Test creates associated health records for `@user`
- [ ] Test calls `DELETE /account` with correct confirmation
- [ ] Test asserts all associated models return 0 records for `@user.id`
- [ ] Covers at least: SymptomLog, PeakFlowReading, Medication, DoseLog, HealthEvent

## Work Log

- 2026-03-10: Identified by kieran-rails-reviewer in Phase 16 code review.
