---
status: pending
priority: p2
issue_id: "094"
tags: [code-review, security, rails, peak-flow, validation]
dependencies: []
---

# `rescue nil` on `Date.parse` silently widens query to full history on malformed input

## Problem Statement

When `start_date` or `end_date` params are present but malformed (e.g. `start_date=not-a-date`), `rescue nil` silently returns `nil`. The fallback then substitutes `Time.at(0)` (Unix epoch) as the start bound, producing a WHERE clause spanning the user's entire peak flow history. The user asked for a filtered view and gets everything — a data minimisation failure with HIPAA relevance. The `rescue nil` also catches all exception classes, not just `ArgumentError` from malformed dates.

This same smell exists in `symptom_logs_controller.rb` and was inherited rather than improved.

## Findings

**Flagged by:** security-sentinel (P2), kieran-rails-reviewer (P2), performance-oracle (P3), pattern-recognition-specialist (P2)

**Location:** `app/controllers/peak_flow_readings_controller.rb:34-35`

```ruby
@start_date = params[:start_date].present? ? (Date.parse(params[:start_date]) rescue nil) : nil
@end_date   = params[:end_date].present?   ? (Date.parse(params[:end_date])   rescue nil) : nil
```

**What happens on `?start_date=not-a-date`:**
1. `Date.parse("not-a-date")` raises `ArgumentError`
2. `rescue nil` returns `nil`
3. `@start_date` is `nil`
4. Controller uses `Time.at(0)` as lower bound
5. User sees all historical readings instead of an error

## Proposed Solutions

### Option A: Extract to a private helper, scope to `ArgumentError`, return 400 on failure (Recommended)

```ruby
private

def parse_date_param(key)
  value = params[key]
  return nil if value.blank?
  Date.parse(value)
rescue ArgumentError
  nil  # caller should check and handle
end
```

Then in the index action:
```ruby
@start_date = parse_date_param(:start_date)
@end_date   = parse_date_param(:end_date)

# Detect malformed input: param present but failed to parse
if (params[:start_date].present? && @start_date.nil?) ||
   (params[:end_date].present? && @end_date.nil?)
  flash.now[:alert] = "Invalid date format. Showing 30-day default."
  @active_preset = "30"
  @start_date = Date.current - 30.days
  @end_date   = nil
end
```

Move the same helper to `ApplicationController` and apply to `SymptomLogsController` too.

- **Pros:** Scoped exception; user-visible feedback; no silent full-history dump; reusable across controllers
- **Effort:** Small
- **Risk:** Minor — adds flash on malformed input (strictly better UX)

### Option B: Scope rescue to `ArgumentError` only (Minimal fix)

```ruby
@start_date = params[:start_date].present? ? (Date.parse(params[:start_date]) rescue ArgumentError => nil) : nil
```

Note: this is not valid Ruby syntax — `rescue ArgumentError` without a block doesn't work inline this way. The correct inline form is `rescue ArgumentError; nil` or extract to a method.

- **Effort:** Small
- **Cons:** Still silently falls back without user feedback

## Recommended Action

Option A — extract to `ApplicationController` private helper and apply to both controllers. Also fixes the pre-existing issue in `symptom_logs_controller.rb`.

## Technical Details

- **Affected files:** `app/controllers/peak_flow_readings_controller.rb`, `app/controllers/symptom_logs_controller.rb`, `app/controllers/application_controller.rb`

## Acceptance Criteria

- [ ] `?start_date=not-a-date` does not silently return all historical readings
- [ ] Malformed date input shows a user-visible error or falls back to a documented default
- [ ] `rescue` is scoped to `ArgumentError` only, not all exceptions
- [ ] Same fix applied to `symptom_logs_controller.rb`

## Work Log

- 2026-03-07: Identified during Phase 7 code review
