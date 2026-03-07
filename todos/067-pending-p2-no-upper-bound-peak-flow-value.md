---
status: pending
priority: p2
issue_id: "067"
tags: [code-review, security, validation, rails]
dependencies: []
---

# No Upper Bound on `PeakFlowReading#value` — Accepts Physiologically Impossible Values

## Problem Statement

`PersonalBestRecord` correctly validates value between 100 and 900 L/min. `PeakFlowReading` only validates `greater_than: 0` — accepting any positive integer up to SQLite's INTEGER max (2,147,483,647). A user or API client can persist `value: 999999`, which would flow through zone calculation (producing a nonsensical "Green Zone (192307% of personal best)" flash) and could influence medical decisions.

## Findings

**Flagged by:** security-sentinel

**Location:** `app/models/peak_flow_reading.rb:7-8`

```ruby
validates :value, presence: true,
                  numericality: { only_integer: true, greater_than: 0 }
```

**Contrast with PersonalBestRecord:**
```ruby
validates :value, presence: true,
                  numericality: { only_integer: true,
                                  greater_than_or_equal_to: 100,
                                  less_than_or_equal_to: 900,
                                  message: "must be between 100 and 900 L/min" }
```

**Form partial:** only has `min: 1`, no `max` attribute.

```erb
<%= form.number_field :value, min: 1, placeholder: "e.g. 430", ... %>
```

## Proposed Solutions

### Option A: Add clinical ceiling of 900 L/min (Recommended)

Peak flow readings are clinically bounded by personal best. Since personal best is capped at 900, readings above ~1000 are not physiologically meaningful. Align with PersonalBestRecord's ceiling:

```ruby
validates :value, presence: true,
                  numericality: { only_integer: true,
                                  greater_than: 0,
                                  less_than_or_equal_to: 900,
                                  message: "must be between 1 and 900 L/min" }
```

Also add `max: 900` to the form field.

**Pros:** Consistent with PersonalBestRecord; prevents impossible values; client gets helpful error
**Cons:** Theoretical edge case where world-record athlete exceeds 900 (clinically negligible)
**Effort:** XSmall
**Risk:** Zero

### Option B: Add a higher ceiling (e.g. 1000)

Allow readings slightly above the personal best ceiling to handle edge cases.

```ruby
less_than_or_equal_to: 1000
```

**Pros:** Slightly more permissive for unusual cases
**Cons:** Arbitrary; the personal best cap at 900 already defines the clinical ceiling
**Effort:** XSmall
**Risk:** Zero

## Recommended Action

Option A — match the PersonalBestRecord ceiling for consistency.

## Technical Details

**Affected files:**
- `app/models/peak_flow_reading.rb`
- `app/views/peak_flow_readings/_form.html.erb` (add `max: 900` to number_field)

**Test to add:**
```ruby
test "invalid when value exceeds 900" do
  reading = PeakFlowReading.new(valid_attributes.merge(value: 950))
  assert_not reading.valid?
  assert reading.errors[:value].any?
end
```

## Acceptance Criteria

- [ ] `PeakFlowReading` validates `value` with `less_than_or_equal_to: 900`
- [ ] Form field has `max: 900`
- [ ] Test covers the upper bound rejection
- [ ] Existing tests still pass

## Work Log

- 2026-03-07: Identified by security-sentinel during Phase 6 code review
