---
status: pending
priority: p3
issue_id: "387"
tags: [code-review, rails, patterns, duplication]
dependencies: []
---

## Problem Statement
SymptomLogPolicy, PeakFlowReadingPolicy, HealthEventPolicy, and MedicationPolicy share identical method bodies (index?/show?/create?/update?/destroy?/Scope). MedicationPolicy adds only `refill?`. This is ~90 lines of duplication across 4 files. When authorization logic changes, all four files must be updated in lockstep.

## Findings
All four policies implement the same owner-based CRUD pattern: each method delegates to an `owner?` check, and each Scope resolves to `user.{association}`. MedicationPolicy is the sole outlier, adding a single `def refill? = owner?` method.

## Proposed Solutions
### Option A: Extract OwnerCrudPolicy base class
Create an `OwnerCrudPolicy` base class that all four inherit from. MedicationPolicy adds `def refill? = owner?`. Pros: DRY, one place to update authorization logic. Cons: less explicit per-model. Effort: Small.

### Option B: Leave as-is for auditability
Each policy remains self-contained and independently auditable. Pros: no inheritance to trace. Cons: 4x maintenance burden. Effort: None.

## Acceptance Criteria
- [ ] If extracted, all 4 policies inherit from OwnerCrudPolicy
- [ ] All tests pass
