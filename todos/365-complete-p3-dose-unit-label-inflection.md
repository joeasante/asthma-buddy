---
status: complete
priority: p3
issue_id: 365
tags: [code-review, simplification]
dependencies: []
---

## Problem Statement

`Medication#dose_unit_label` uses a 10-line case statement to manually handle singular/plural forms for 3 units. This could be reduced to 3 lines using Rails' built-in `singularize`/`pluralize` inflection helpers, which handle edge cases like "ml" correctly.

## Findings

The current implementation manually maps each dose unit to its singular and plural form via a case statement. Rails' inflection API already provides this functionality out of the box, making the manual mapping unnecessary boilerplate.

## Proposed Solutions

- Replace the case statement with a call to `singularize`/`pluralize` based on the dose count.
- Verify that Rails inflections handle all current unit strings correctly (puffs, mcg, ml).
- Add any custom inflection rules to `config/initializers/inflections.rb` if needed.

## Technical Details

**Affected files:** app/models/medication.rb

## Acceptance Criteria

- [ ] `dose_unit_label` method uses Rails inflection helpers instead of manual case statement
- [ ] All existing unit types (puffs, mcg, ml) return correct singular/plural forms
- [ ] Existing tests continue to pass
