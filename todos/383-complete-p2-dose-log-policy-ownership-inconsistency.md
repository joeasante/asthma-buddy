---
status: pending
priority: p2
issue_id: "383"
tags: [code-review, rails, patterns]
dependencies: []
---

## Problem Statement
Every other policy uses the `owner?` helper from ApplicationPolicy (`record.user == user`), but `DoseLogPolicy#destroy?` traverses `record.medication.user`. DoseLog has a direct `user` association (controller sets `@dose_log.user = Current.user`), so `owner?` should work. The traversal also triggers a lazy-load of the medication association (extra DB query) if `inverse_of` is not set.

## Findings
- All other policies use `owner?` helper from ApplicationPolicy
- `DoseLogPolicy#destroy?` uses `record.medication.user` instead
- DoseLog has a direct `user` association set by the controller
- The traversal through `medication` triggers an unnecessary lazy-load query

## Proposed Solutions
### Option A: Use owner? and add inverse_of
Change `DoseLogPolicy#destroy?` to use `owner?` and ensure `Medication` has `has_many :dose_logs` with `inverse_of: :medication`.

**Pros:** Consistent pattern, eliminates extra query.
**Effort:** Small.
**Risk:** Low.

## Acceptance Criteria
- [ ] `DoseLogPolicy` uses `owner?` for all actions
- [ ] `Medication` has `inverse_of: :medication` on `dose_logs` association
