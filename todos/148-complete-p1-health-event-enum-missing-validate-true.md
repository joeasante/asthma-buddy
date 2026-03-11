---
status: complete
priority: p1
issue_id: "148"
tags: [code-review, rails, validation, security, health-events]
dependencies: []
---

# `HealthEvent` enum missing `validate: true`

## Problem Statement

The `event_type` enum on `HealthEvent` is missing `validate: true`. Every other enum in the codebase uses this option. Without it, an invalid `event_type` value bypasses validation, either raising an `ArgumentError` (500) or — for string-backed enums — silently persisting an arbitrary string to the database.

## Findings

**Flagged by:** kieran-rails-reviewer, security-sentinel, architecture-strategist, pattern-recognition-specialist (all 4 agents unanimous — highest confidence)

**Location:** `app/models/health_event.rb`, lines 5–11

**Current code:**
```ruby
enum :event_type, {
  hospital_visit:    "hospital_visit",
  gp_appointment:    "gp_appointment",
  illness:           "illness",
  medication_change: "medication_change",
  other:             "other"
}
```

**Established pattern in this codebase:**
- `SymptomLog#symptom_type` — `validate: true`
- `SymptomLog#severity` — `validate: true`
- `Medication#medication_type` — `validate: true`
- `PeakFlowReading#zone` — `validate: { allow_nil: true }`

**Security risk:** The `event_type` column is type `string` in the database (not integer). Without `validate: true`, a crafted POST with `health_event[event_type]=<arbitrary>` passes `validates :event_type, presence: true` (the string is non-blank) and persists the raw attacker-controlled value to the DB. Downstream code (`event_type_css_modifier`, CSS class interpolation in `_event_row.html.erb`) operates on the raw value.

## Proposed Solutions

### Option A — Add `validate: true` (Recommended)
```ruby
enum :event_type, {
  hospital_visit:    "hospital_visit",
  gp_appointment:    "gp_appointment",
  illness:           "illness",
  medication_change: "medication_change",
  other:             "other"
}, validate: true
```

**Pros:** One-word fix. Matches all other enums. Prevents invalid values.
**Effort:** Trivial
**Risk:** None

### Option B — `validate: true` + explicit `inclusion` validation (defence in depth)
```ruby
enum :event_type, { ... }, validate: true

validates :event_type,
  presence: true,
  inclusion: { in: event_types.keys.map(&:to_s) }
```

**Pros:** Double protection — enum validate + explicit inclusion guard.
**Effort:** Small
**Risk:** None

## Recommended Action

Option A minimum; Option B preferred for a medical app with PHI data.

## Technical Details

**Affected file:** `app/models/health_event.rb`
**Test coverage:** `test/models/health_event_test.rb` — add a test:
```ruby
test "invalid with unrecognized event_type" do
  event = HealthEvent.new(valid_attributes.merge(event_type: "hacked"))
  assert_not event.valid?
  assert event.errors[:event_type].any?
end
```

## Acceptance Criteria

- [ ] `enum :event_type, { ... }, validate: true` present in `health_event.rb`
- [ ] `HealthEvent.new(event_type: "hacked").valid?` returns `false` with an `event_type` error
- [ ] Existing model tests still pass
- [ ] `bin/rails test test/models/health_event_test.rb` exits 0

## Work Log

- 2026-03-09: Identified by all 4 review agents during `ce:review` of Phase 15.

## Resources

- `app/models/symptom_log.rb` — reference pattern for `validate: true`
- `app/models/medication.rb` — reference pattern for `validate: true`
