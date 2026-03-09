---
status: pending
priority: p2
issue_id: "133"
tags: [code-review, ux, symptom-logs, filtering]
dependencies: []
---

# Severity Counts Computed Post-Filter — Filter Bar Shows Wrong Totals

## Problem Statement

`@severity_counts` is computed from `base_relation` AFTER the severity filter is applied. When a user filters by "mild," the trend bar shows `mild: N, moderate: 0, severe: 0` instead of the actual total counts across all severities. This makes the filter bar useless for navigation — users cannot see how many moderate/severe logs exist while a filter is active.

Flagged by: kieran-rails-reviewer, architecture-strategist.

## Findings

**File:** `app/controllers/symptom_logs_controller.rb`

```ruby
# Filter applied first:
base_relation = base_relation.where(severity: @active_severity) if @active_severity.present?

# Then counts computed from the already-filtered relation:
@severity_counts = { mild: 0, moderate: 0, severe: 0 }.merge(base_relation.severity_counts)
```

The correct behavior: severity counts should reflect the date-range-filtered set BEFORE the severity filter is applied, so the trend bar always shows the full distribution and acts as a navigation aid.

## Proposed Solution

Compute `@severity_counts` from the base relation before applying the severity filter:

```ruby
# Date-range filtered but NOT severity filtered:
base_counts_relation = Current.user.symptom_logs
                              .in_date_range(@start_date, @end_date)
@severity_counts = { mild: 0, moderate: 0, severe: 0 }.merge(base_counts_relation.severity_counts)

# Apply severity filter to base_relation for the actual record set:
base_relation = base_relation.where(severity: @active_severity) if @active_severity.present?
```

This is one extra SQL query (COUNT GROUP BY severity), but it's fast and cached if the result set hasn't changed.

## Acceptance Criteria

- [ ] Filtering by "mild" shows correct non-zero counts for "moderate" and "severe" in the trend bar
- [ ] "Clear filter" link appears when a severity filter is active
- [ ] `symptom_logs_controller_test.rb` has a test: filter by severity → assert all three severity counts are non-zero in the response
- [ ] JSON `applied_filters.severity` still reflects the active filter

## Work Log

- 2026-03-08: Identified by kieran-rails-reviewer and architecture-strategist
