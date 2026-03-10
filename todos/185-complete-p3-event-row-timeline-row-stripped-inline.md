---
status: pending
priority: p3
issue_id: "185"
tags: [code-review, css, show-pages, design-system]
dependencies: []
---

# event-row and timeline-row Have Card Chrome Stripped with Inline Styles in Show Views

## Problem Statement
health_events/show.html.erb line 22 uses `class="event-row" style="border: none; padding: 0;"`. symptom_logs/show.html.erb line 22 uses `class="timeline-row" style="border: none; padding: 0; box-shadow: none;"`. Both are reusing list-row components in a single-record context but needing to undo the list-specific card chrome via inline overrides. The intent is a stripped/embedded variant of each row type.

## Proposed Solutions

### Option A
Add `.event-row--flat` modifier to health_events.css with `{ border: none; padding: 0; box-shadow: none; }`. Add `.timeline-row--embedded` to symptom_timeline.css with same. Update the show views to use these modifiers instead of inline overrides.
- Effort: Small
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: app/views/health_events/show.html.erb, app/views/symptom_logs/show.html.erb, app/assets/stylesheets/health_events.css, app/assets/stylesheets/symptom_timeline.css

## Acceptance Criteria
- [ ] `.event-row--flat` modifier defined in health_events.css
- [ ] `.timeline-row--embedded` modifier defined in symptom_timeline.css
- [ ] health_events/show.html.erb uses `event-row event-row--flat` with no inline style attribute
- [ ] symptom_logs/show.html.erb uses `timeline-row timeline-row--embedded` with no inline style attribute
- [ ] Visual appearance of both show pages is unchanged

## Work Log
- 2026-03-10: Created via code review
