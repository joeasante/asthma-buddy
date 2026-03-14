---
status: complete
priority: p3
issue_id: 371
tags: [code-review, magic-numbers]
dependencies: []
---

## Problem Statement

The peak flow view contains a magic number: `@current_personal_best.recorded_at < 12.months.ago`. The 12-month threshold for considering a personal best "stale" should be extracted to a named constant for clarity and maintainability.

## Findings

The 12-month threshold is embedded directly in the view template, making it non-obvious what the business rule is and harder to change if the threshold needs adjustment. The logic also belongs in the model layer rather than the view.

## Proposed Solutions

- Define a constant like `PersonalBestRecord::STALE_THRESHOLD = 12.months` in the model.
- Add a model method like `PersonalBestRecord#stale?` that encapsulates the check.
- Update the view to use `@current_personal_best.stale?` instead of the inline comparison.

## Technical Details

**Affected files:** app/views/peak_flow_readings/index.html.erb

## Acceptance Criteria

- [ ] Named constant defined for the stale threshold duration
- [ ] Model method (`stale?` or similar) encapsulates the staleness check
- [ ] View uses the model method instead of inline date comparison
- [ ] Existing tests pass; new unit test covers the `stale?` method
