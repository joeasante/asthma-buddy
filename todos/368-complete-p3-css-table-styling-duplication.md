---
status: complete
priority: p3
issue_id: 368
tags: [code-review, css, duplication]
dependencies: []
---

## Problem Statement

`.admin-table` and `.appt-table` have near-identical CSS styles defined separately. This duplication increases maintenance burden and risks divergence over time.

## Findings

Both table style blocks share the same base styling (borders, padding, header formatting, row striping, responsive behavior). The only differences are minor contextual tweaks. A shared `.data-table` base class would eliminate the duplication.

## Proposed Solutions

- Extract shared table styles into a `.data-table` base class in a common stylesheet.
- Have `.admin-table` and `.appt-table` extend the base class with only their unique overrides.
- Update views to include the `.data-table` class alongside the specific class.

## Technical Details

**Affected files:** app/assets/stylesheets/admin.css, app/assets/stylesheets/appointment_summary.css

## Acceptance Criteria

- [ ] Shared `.data-table` base class created with common table styles
- [ ] `.admin-table` and `.appt-table` use the base class and only define overrides
- [ ] Visual appearance of both table types is unchanged
- [ ] No CSS regressions in admin or appointment summary views
