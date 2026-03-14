---
status: pending
priority: p3
issue_id: "390"
tags: [code-review, rails, data-integrity]
dependencies: []
---

## Problem Statement
The `value` column in SiteSetting stores "true"/"false" as strings with no validation. A direct DB edit or future code path setting "yes" or "1" would silently close registration (fail-closed, which is safe, but confusing to debug).

## Findings
SiteSetting relies on string comparison for boolean semantics but has no model-level validation ensuring the value is actually "true" or "false". Any non-"true" string value would be treated as false.

## Proposed Solutions
### Option A: Add inclusion validation
Add `validates :value, inclusion: { in: %w[true false] }, if: -> { key == "registration_open" }` to the SiteSetting model. Effort: Small.

## Acceptance Criteria
- [ ] Validation prevents non-boolean string values for the `registration_open` key
- [ ] All tests pass
