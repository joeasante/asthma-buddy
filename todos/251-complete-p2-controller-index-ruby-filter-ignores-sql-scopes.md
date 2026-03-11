---
status: pending
priority: p2
issue_id: "251"
tags: [code-review, rails, performance, architecture]
dependencies: []
---

# `MedicationsController#index` Ruby-Level Filter Ignores Existing SQL Scopes

## Problem Statement

The controller loads all medications into memory and partitions them in Ruby using inline `course?` + `course_active?` predicates. The `Medication` model already defines three SQL scopes (`active_courses`, `archived_courses`, `non_courses`) that express exactly this partition. The controller doesn't use them, meaning the scope definitions and the controller filter logic can diverge silently.

## Findings

`app/controllers/settings/medications_controller.rb` lines 8–10:

```ruby
all_medications = Current.user.medications.chronological.includes(:dose_logs)
@active_medications  = all_medications.reject { |m| m.course? && !m.course_active? }
@archived_courses    = all_medications.select { |m| m.course? && !m.course_active? }
```

`app/models/medication.rb` defines the canonical SQL scopes:

```ruby
scope :active_courses,   -> { where(course: true).where("ends_on >= ?", Date.current) }
scope :archived_courses, -> { where(course: true).where("ends_on < ?", Date.current) }
scope :non_courses,      -> { where(course: false) }
```

The controller doesn't use them. If the archival boundary condition ever changes in the scopes, the controller filter must be manually kept in sync. There is no automated protection against drift.

The Ruby-level partition is justified when using `includes(:dose_logs)` — you can't do SQL-level filtering on an already-materialized association. However, the partition logic should point at the model scopes rather than re-encoding them inline.

Confirmed by: code-simplicity-reviewer, architecture-strategist, pattern-recognition-specialist.

## Proposed Solutions

### Option A — Add a comment linking to model scopes *(Low effort)*

```ruby
def index
  # Load all once (single query + eager-load). Partition in Ruby rather than
  # firing two separate queries, so we avoid a TOCTOU race and keep includes.
  # The boundary condition mirrors Medication.active_courses / archived_courses.
  all_medications = Current.user.medications.chronological.includes(:dose_logs)
  @active_medications = all_medications.reject { |m| m.course? && !m.course_active? }
  @archived_courses   = all_medications.select { |m| m.course? && !m.course_active? }
end
```

Pros: zero risk, documents the intentional trade-off
Cons: doesn't remove the duplication risk

### Option B — Use `.or` to build SQL query, rely on AR's already-loaded association cache *(Recommended)*

```ruby
def index
  base = Current.user.medications.chronological.includes(:dose_logs)
  @active_medications = base.non_courses.or(base.active_courses).load
  @archived_courses   = base.archived_courses.load

  @header_medication_count = @active_medications.size
  @header_low_stock_count  = @active_medications.count(&:low_stock?)
end
```

This fires two queries instead of one but uses the canonical SQL scopes. For typical user medication counts (5–20 records) this is negligible.

Pros: uses the scopes as the single source of truth, eliminates drift risk
Cons: two queries vs one

## Recommended Action

Option A as a minimum (document the trade-off). Option B if the team prefers scope correctness over the micro-optimization.

## Technical Details

- **Affected file:** `app/controllers/settings/medications_controller.rb`
- **Related:** `app/models/medication.rb` scope definitions

## Acceptance Criteria

- [ ] Either: controller comment documents the partition rationale and references model scopes
- [ ] Or: controller uses model scopes via `.or` query
- [ ] Either way: all existing controller tests pass

## Work Log

- 2026-03-10: Found by code-simplicity, architecture-strategist, pattern-recognition during Phase 18 code review
