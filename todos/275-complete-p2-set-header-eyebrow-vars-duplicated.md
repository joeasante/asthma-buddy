---
status: pending
priority: p2
issue_id: "275"
tags: [code-review, rails, architecture, dry, settings]
dependencies: []
---

# `set_header_eyebrow_vars` duplicated across two Settings controllers

## Problem Statement

The private method `set_header_eyebrow_vars` is defined byte-for-byte identically in both `Settings::DoseLogsController` and `Settings::MedicationsController`. Both controllers are in the same `Settings` namespace and update the same DOM target (`medications-page-header`). There is no shared base class — both inherit directly from `ApplicationController`.

If the visibility rule changes (e.g. "include archived courses in the count"), both files must be updated in sync. One will inevitably be missed.

## Findings

- **Files:** `app/controllers/settings/dose_logs_controller.rb:42–47` and `app/controllers/settings/medications_controller.rb:104–109`
- **Agents:** architecture-strategist, pattern-recognition-specialist, code-simplicity-reviewer

```ruby
# IDENTICAL in both files
def set_header_eyebrow_vars
  all_meds = Current.user.medications.chronological.includes(:dose_logs)
  visible  = all_meds.reject { |m| m.course? && !m.course_active? }
  @header_medication_count = visible.size
  @header_low_stock_count  = visible.count(&:low_stock?)
end
```

## Proposed Solutions

### Option A — Create `Settings::BaseController` (Recommended)

```ruby
# app/controllers/settings/base_controller.rb
class Settings::BaseController < ApplicationController
  private

  def set_header_eyebrow_vars
    all_meds = Current.user.medications.chronological.includes(:dose_logs)
    visible  = all_meds.reject { |m| m.course? && !m.course_active? }
    @header_medication_count = visible.size
    @header_low_stock_count  = visible.count(&:low_stock?)
  end
end
```

Both `Settings::DoseLogsController` and `Settings::MedicationsController` inherit from `Settings::BaseController`. `Settings::AccountsController` can also inherit from it.

**Pros:** Single source of truth. Idiomatic Rails pattern. Mechanical change with zero functional risk.
**Cons:** None.
**Effort:** Small
**Risk:** Low

### Option B — Extract to a `SettingsHelper` module

Include via `include Settings::EyebrowHelper`.

**Pros:** Avoids inheritance.
**Cons:** Module inclusion is less idiomatic than a base controller for shared controller behaviour.
**Effort:** Small
**Risk:** Low

## Recommended Action

Option A — `Settings::BaseController`. This is the standard Rails solution.

## Technical Details

- **Affected files:**
  - `app/controllers/settings/dose_logs_controller.rb`
  - `app/controllers/settings/medications_controller.rb`
  - New: `app/controllers/settings/base_controller.rb`

## Acceptance Criteria

- [ ] `Settings::BaseController` created with the shared method
- [ ] Both controllers inherit from it
- [ ] Existing tests pass without modification
- [ ] No functional change to eyebrow stat updates

## Work Log

- 2026-03-11: Identified by architecture-strategist, pattern-recognition-specialist, code-simplicity-reviewer during code review of dev branch
