---
status: pending
priority: p3
issue_id: "388"
tags: [code-review, rails, dead-code]
dependencies: []
---

## Problem Statement
HealthEventPolicy::Scope, MedicationPolicy::Scope, NotificationPolicy::Scope, PeakFlowReadingPolicy::Scope, SymptomLogPolicy::Scope, and DoseLogPolicy::Scope are defined but never called via `policy_scope`. All controllers scope through `Current.user` associations instead. These are YAGNI — they add maintenance burden without being used.

## Findings
Six policy Scope classes exist across the codebase but none are invoked. Controllers consistently use `Current.user.symptom_logs`, `Current.user.medications`, etc. for scoping rather than Pundit's `policy_scope` mechanism.

## Proposed Solutions
### Option A: Remove unused Scope classes
Delete the unused Scope inner classes from all six policies. Pros: less code to maintain. Cons: would need re-adding if `policy_scope` is adopted later. Effort: Small.

### Option B: Keep as documentation of intended scope behavior
The Scope classes serve as documentation of how scoping should work if `policy_scope` is ever adopted. Effort: None.

## Acceptance Criteria
- [ ] If removed, no tests reference `policy_scope` for these models
- [ ] All tests pass
