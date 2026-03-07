---
status: pending
priority: p3
issue_id: "102"
tags: [code-review, rails, css, peak-flow, maintainability]
dependencies: []
---

# Zone CSS modifier derived directly from enum string — fragile if enum values change

## Problem Statement

`_reading_row.html.erb` interpolates `reading.zone` directly into the CSS class name (`zone-badge--<%= badge_modifier %>`). This couples the enum string values (`"green"`, `"yellow"`, `"red"`) directly to CSS class names. If the enum values are ever renamed (e.g. to numeric codes or medical zone names), the CSS silently breaks with no compiler warning. An explicit allowlist or model helper would make the coupling visible and intentional.

## Findings

**Flagged by:** security-sentinel (P3), pattern-recognition-specialist (P3-C, noted as currently correct)

**Location:** `app/views/peak_flow_readings/_reading_row.html.erb:9-10`

```erb
<% badge_modifier = reading.zone.present? ? reading.zone : "none" %>
<span class="zone-badge zone-badge--<%= badge_modifier %>">
```

Currently safe because the enum is `{ green: 0, yellow: 1, red: 2 }` and CSS has exactly `zone-badge--green/yellow/red/none`. But the coupling is implicit.

## Proposed Solutions

### Option A: Add `zone_css_modifier` helper method to model (Recommended)

```ruby
# app/models/peak_flow_reading.rb
def zone_css_modifier
  zone.presence || "none"
end
```

```erb
<span class="zone-badge zone-badge--<%= reading.zone_css_modifier %>">
```

- **Pros:** Single place to change if enum values diverge from CSS names; intent explicit; testable
- **Effort:** Tiny
- **Risk:** None

### Option B: Add explicit allowlist in the view

```erb
<% ZONE_CSS = { "green" => "green", "yellow" => "yellow", "red" => "red" } %>
<% badge_modifier = ZONE_CSS.fetch(reading.zone.to_s, "none") %>
```

- **Effort:** Tiny
- **Cons:** Logic in view rather than model

## Recommended Action

Option A — model helper method. Clean and testable.

## Technical Details

- **Affected files:** `app/models/peak_flow_reading.rb`, `app/views/peak_flow_readings/_reading_row.html.erb`

## Acceptance Criteria

- [ ] `PeakFlowReading#zone_css_modifier` exists and returns `"none"` when zone is nil
- [ ] View uses `reading.zone_css_modifier` instead of inline ternary
- [ ] Unit test covers nil zone → "none", each zone value → same string

## Work Log

- 2026-03-07: Identified during Phase 7 code review
