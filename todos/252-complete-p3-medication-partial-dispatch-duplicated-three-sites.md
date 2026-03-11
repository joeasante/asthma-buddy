---
status: pending
priority: p3
issue_id: "252"
tags: [code-review, duplication, rails, views, refactor]
dependencies: []
---

# `if medication.course?` Partial Dispatch Duplicated Across 3 View Sites

## Problem Statement

The same `if medication.course? / render course_medication / else / render medication` branch appears verbatim in three places. Any future medication partial variant requires updating all three sites.

## Findings

1. `app/views/settings/medications/index.html.erb` lines 40–44
2. `app/views/settings/medications/create.turbo_stream.erb` lines 4–8 (first-medication case)
3. `app/views/settings/medications/create.turbo_stream.erb` lines 12–16 (prepend case)

Additionally, `update.turbo_stream.erb` is missing the branch entirely (#247 — separate P1 fix). Once #247 is fixed, it adds a fourth site.

Confirmed by: code-simplicity-reviewer, kieran-rails-reviewer, pattern-recognition-specialist.

## Proposed Solutions

### Option A — Add `MedicationsHelper#medication_partial` *(Recommended)*

```ruby
# app/helpers/medications_helper.rb
module MedicationsHelper
  def medication_partial(medication)
    medication.course? ? "settings/medications/course_medication" : "settings/medications/medication"
  end
end
```

Then all call sites become:

```erb
<%= render medication_partial(medication), medication: medication %>
```

Pros: one decision point, future-proof for new variants
Cons: small helper file addition

### Option B — Override `to_partial_path` on Medication model

```ruby
def to_partial_path
  course? ? "settings/medications/course_medication" : "settings/medications/medication"
end
```

Then use `<%= render medication %>` everywhere.

Pros: most Rails-idiomatic (model controls its own partial path)
Cons: couples the model to a specific controller namespace path; affects all render sites project-wide

## Recommended Action

Option A — simple, contained, no model coupling.

## Technical Details

- **Files to modify:** `app/views/settings/medications/index.html.erb`, `create.turbo_stream.erb`, `update.turbo_stream.erb` (after #247)
- **New file (or update):** `app/helpers/medications_helper.rb`
- **Do after:** #247 (update stream fix)

## Acceptance Criteria

- [ ] `MedicationsHelper#medication_partial` added
- [ ] All three (or four post-#247) dispatch sites use the helper
- [ ] No visual change to the medications index
- [ ] Controller and system tests pass

## Work Log

- 2026-03-10: Found during Phase 18 code review
