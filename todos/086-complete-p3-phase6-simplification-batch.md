---
status: pending
priority: p3
issue_id: "086"
tags: [code-review, simplification, rails, quality]
dependencies: ["077"]
---

# Phase 6 Simplification Batch — Three Small Cleanups

## Problem Statement

Three minor simplifications identified in Phase 6 code: (1) `compute_zone` and `zone_percentage` duplicate the personal-best guard and percentage formula, (2) `zone_flash_message` has unnecessary intermediate locals, (3) `current_for` fetches a full row when only presence is checked. None are bugs, all reduce maintenance surface.

## Findings

**Flagged by:** code-simplicity-reviewer, performance-oracle (P3-D)

### Simplification 1: Extract shared `zone_pct` from `compute_zone` and `zone_percentage`

`app/models/peak_flow_reading.rb:24–42` — both methods repeat the guard and formula:

```ruby
# Current — duplicated in both methods:
pb = personal_best_at_reading_time
return nil if pb.nil? || pb.zero?
percentage = (value.to_f / pb) * 100
```

**Proposed:**
```ruby
def compute_zone
  pct = zone_pct
  return nil if pct.nil?
  pct >= 80 ? :green : (pct >= 50 ? :yellow : :red)
end

def zone_percentage
  zone_pct&.round
end

private

def zone_pct
  pb = personal_best_at_reading_time
  return nil if pb.nil? || pb.zero?
  (value.to_f / pb) * 100
end
```

Delta: -4 LOC. Prevents the formula from drifting between the two methods in future edits.

### Simplification 2: Inline intermediate locals in `zone_flash_message`

`app/controllers/peak_flow_readings_controller.rb:46–54` — three intermediate variables add lines without clarity:

```ruby
# Current:
zone_name = reading.zone.capitalize
pct       = reading.zone_percentage
coloured  = "<span ...>#{zone_name} Zone (#{pct}% ...)</span>"
"Reading saved \u2014 #{coloured}.".html_safe

# Proposed (after fixing the html_safe issue in todo 074):
span = content_tag(:span, "#{reading.zone.capitalize} Zone (#{reading.zone_percentage}% of personal best)",
                   class: "zone-label zone-label--#{reading.zone}")
safe_join(["Reading saved \u2014 ", span, "."])
```

Delta: -3 LOC.

### Simplification 3: Replace `current_for(...).present?` with `exists?`

`app/models/personal_best_record.rb` — add a companion method:

```ruby
def self.exists_for?(user)
  user.personal_best_records.exists?
end
```

`EXISTS (SELECT 1 ...)` is faster than `SELECT * ... LIMIT 1`. All three call sites in `PeakFlowReadingsController` that check `.present?` become `PersonalBestRecord.exists_for?(Current.user)`.

Note: this should be done in conjunction with todo 077 (before_action consolidation) and only after todo 074 (html_safe fix) is complete for Simplification 2.

## Proposed Solutions

Apply all three in a single commit. They are independent of each other but small enough to batch.

## Technical Details

**Affected files:**
- `app/models/peak_flow_reading.rb`
- `app/models/personal_best_record.rb`
- `app/controllers/peak_flow_readings_controller.rb`

## Acceptance Criteria

- [ ] `compute_zone` and `zone_percentage` delegate to a shared private `zone_pct` method
- [ ] `PersonalBestRecord.exists_for?` method exists and uses `EXISTS` query
- [ ] `bin/rails test` passes with 0 failures

## Work Log

- 2026-03-07: Identified by code-simplicity-reviewer and performance-oracle in Phase 6 code review
