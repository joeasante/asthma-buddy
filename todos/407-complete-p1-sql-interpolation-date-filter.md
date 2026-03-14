---
status: complete
priority: p1
issue_id: "407"
tags: [code-review, security, sql-injection, api]
dependencies: []
---

# SQL Column Name Interpolation in `date_filter`

## Problem Statement

The `date_filter` method in `Api::V1::BaseController` interpolates the `date_column` parameter directly into a SQL string. While currently only called with hardcoded symbols (`:recorded_at`), this is a latent SQL injection vector. If a future developer passes user-controlled input as the column name, it becomes exploitable. For a health data app under UK GDPR, this pattern is unacceptable.

## Findings

**Flagged by:** ALL 6 review agents (unanimous) — kieran-rails-reviewer, security-sentinel, performance-oracle, architecture-strategist, pattern-recognition-specialist, code-simplicity-reviewer

**Location:** `app/controllers/api/v1/base_controller.rb`, lines 63-66

```ruby
def date_filter(scope, date_column: :recorded_at)
  if params[:date_from].present?
    from_date = Date.parse(params[:date_from])
    scope = scope.where("#{date_column} >= ?", from_date.beginning_of_day)
  end
```

## Proposed Solutions

### Option A: Use Arel (Recommended)
Replace string interpolation with Arel attribute references:

```ruby
def date_filter(scope, date_column: :recorded_at)
  column = scope.arel_table[date_column]

  if params[:date_from].present?
    from_date = Date.parse(params[:date_from])
    scope = scope.where(column.gteq(from_date.beginning_of_day))
  end

  if params[:date_to].present?
    to_date = Date.parse(params[:date_to])
    scope = scope.where(column.lteq(to_date.end_of_day))
  end

  scope
rescue Date::Error
  render_error(status: 400, message: "Invalid date format. Use YYYY-MM-DD.")
  nil
end
```

- **Pros:** Eliminates interpolation entirely, idiomatic Rails
- **Cons:** None
- **Effort:** Small (5 min)
- **Risk:** None

### Option B: Whitelist column names

```ruby
ALLOWED_DATE_COLUMNS = %w[recorded_at created_at].freeze

def date_filter(scope, date_column: :recorded_at)
  col = date_column.to_s
  raise ArgumentError, "Invalid date column: #{col}" unless ALLOWED_DATE_COLUMNS.include?(col)
  # ...existing code...
end
```

- **Pros:** Explicit, documents valid columns
- **Cons:** Must maintain the whitelist
- **Effort:** Small (5 min)
- **Risk:** None

## Acceptance Criteria

- [ ] `date_column` is never interpolated into a SQL string
- [ ] All existing tests pass
- [ ] Date filtering still works for all 4 endpoints that use it

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 28 code review | Unanimous finding across all 6 agents |
