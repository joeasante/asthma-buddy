---
status: pending
priority: p2
issue_id: "239"
tags: [code-review, rails, data-integrity, onboarding, transactions]
dependencies: []
---

# Onboarding Submit Writes Not Wrapped in Transaction

## Problem Statement

`submit_1` and `submit_2` each perform two separate database writes — a record creation and a flag update — with no transaction wrapper. If the process crashes or the second write fails after the first succeeds, the user ends up with a persisted record but the onboarding flag still `false`. On the next visit, Step 1 re-renders and submitting again creates a duplicate `PersonalBestRecord`.

## Findings

- `onboarding_controller.rb:26-30` — `create!(personal_best_record)` then `update!(onboarding_personal_best_done: true)` — two separate SQL statements
- `onboarding_controller.rb:41-42` — `@medication.save` then `update!(onboarding_medication_done: true)` — same pattern
- `PersonalBestRecord` has `after_save :recompute_nil_zone_readings` callback — meaning the record IS committed before the second write is attempted
- The `recompute_nil_zone_readings` callback fires twice if a user resubmits (duplicate PB record scenario)
- Performance reviewer confirmed: "The failure mode is inconsistent state"
- Learnings researcher confirmed: active-storage blob solution also illustrates dangers of split two-write patterns

## Proposed Solutions

### Option 1: Wrap in `ApplicationRecord.transaction` (Recommended)

**Approach:**
```ruby
def submit_1
  value = params.dig(:personal_best_record, :value).to_i
  unless value.between?(100, 900)
    @step = 1
    flash.now[:alert] = "Please enter a value between 100 and 900 L/min."
    return render :show, status: :unprocessable_entity
  end

  ApplicationRecord.transaction do
    Current.user.personal_best_records.create!(
      value: value,
      recorded_at: Time.current.change(sec: 0)
    )
    Current.user.update!(onboarding_personal_best_done: true)
  end
  redirect_to onboarding_step_path(2)
end
```

Apply same pattern to `submit_2`.

**Pros:**
- Atomic — either both writes succeed or both are rolled back
- Prevents duplicate PB records on retry
- Industry standard pattern for multi-write operations

**Cons:**
- Slightly longer transaction window (minor, single-user app)

**Effort:** 15 minutes

**Risk:** Low

---

### Option 2: Combine writes using a model callback

**Approach:** Add `after_create :mark_onboarding_personal_best_done` to `PersonalBestRecord`.

**Pros:** Single write path handles the flag

**Cons:** Couples domain model to onboarding wizard logic; violates SRP; callbacks are hidden behavior

**Effort:** 20 minutes

**Risk:** Medium (coupling)

## Recommended Action

Option 1. Two-line transaction wrapper in each submit action.

## Technical Details

**Affected files:**
- `app/controllers/onboarding_controller.rb:26-30` (submit_1)
- `app/controllers/onboarding_controller.rb:41-42` (submit_2)

## Acceptance Criteria

- [ ] `submit_1` wraps `create!` + `update!` in a single transaction
- [ ] `submit_2` wraps `save` + `update!` in a single transaction
- [ ] `bin/rails test` passes

## Work Log

### 2026-03-10 — Code Review Discovery

**By:** Claude Code (ce:review)

**Actions:** Flagged by performance reviewer, architecture reviewer, and Rails reviewer independently.
