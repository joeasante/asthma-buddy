---
status: pending
priority: p3
issue_id: "245"
tags: [code-review, rails, simplicity, onboarding]
dependencies: []
---

# `case @step` with Empty `when 1` Branch — Use `if` Instead

## Problem Statement

`OnboardingController#show` uses a `case @step` statement where `when 1` does nothing (empty with a comment). A `case` with one active branch is just an `if`. The comment `# nothing — Step 1 only needs the personal best value field` exists to explain the absence of code, which is a signal the abstraction is wrong.

## Findings

- `onboarding_controller.rb:9-21`:
  ```ruby
  case @step
  when 1
    # nothing — Step 1 only needs the personal best value field
  when 2
    @medication = Medication.new(...)
  end
  ```
- Simplicity reviewer: "`when 1 # nothing` is code that exists to document the absence of code"
- This is a 2-step wizard that will not become a 5-step wizard without a significant rewrite

## Proposed Solutions

### Option 1: Replace `case` with `if @step == 2`

```ruby
if @step == 2
  @medication = Medication.new(
    user: Current.user,
    medication_type: :reliever,
    standard_dose_puffs: 2,
    sick_day_dose_puffs: 4,
    doses_per_day: 2
  )
end
```

**Effort:** 5 minutes  **Risk:** None

## Recommended Action

Option 1. Trivial cleanup.

## Technical Details

- `app/controllers/onboarding_controller.rb:9-21`

## Acceptance Criteria

- [ ] `case @step` replaced with `if @step == 2`
- [ ] Dead `when 1` branch and its comment removed
- [ ] `bin/rails test` passes

## Work Log

### 2026-03-10 — Code Review Discovery

**By:** Claude Code (ce:review)
