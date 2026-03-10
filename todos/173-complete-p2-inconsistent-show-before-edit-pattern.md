---
status: pending
priority: p2
issue_id: "173"
tags: [code-review, architecture, ux, show-pages]
dependencies: []
---

# Show-Before-Edit Pattern Inconsistently Applied Across Resources

## Problem Statement
Peak flow readings: fully enforced — index cards link to show page, edit/delete only reachable from show page. Symptom logs: show page exists and is linked from dashboard, but the symptom log index still has inline Edit and Delete buttons on every row. Health events: same. This means the mental model for interacting with records differs by resource. Users who learn the peak flow pattern will be confused by the symptom log index still offering direct destructive actions. The show pages for symptom logs and health events are effectively orphaned — reachable from the dashboard but bypassed in their own index.

## Proposed Solutions

### Option A
Complete the migration — remove inline edit/delete from _timeline_row.html.erb (symptom logs) and _event_row.html.erb (health events). Make rows link to show pages. Delete actions accessible only from show/edit pages.
- Effort: Medium
- Risk: Low

### Option B
Revert peak flow to match — restore Edit/Delete to the peak flow reading card. Keep the direct-edit pattern across all three resources.
- Effort: Medium
- Risk: Medium (re-adds accidental edit risk)

### Option C
Document the inconsistency as intentional: peak flow readings require show-before-edit for safety (zone data is clinically significant), while symptoms and events allow direct edit as they are lower-stakes operational data.
- Effort: Small (documentation only)
- Risk: None

## Recommended Action

## Technical Details
- Affected files: app/views/symptom_logs/_timeline_row.html.erb, app/views/health_events/_event_row.html.erb

## Acceptance Criteria
- [ ] A single interaction pattern is applied consistently across all three resources
- [ ] If Option A: _timeline_row.html.erb and _event_row.html.erb have no inline Edit/Delete buttons
- [ ] If Option A: rows link to their respective show pages
- [ ] If Option A: destructive actions are only reachable from show or edit pages
- [ ] If Option C: decision is documented in code comments or architecture notes

## Work Log
- 2026-03-10: Created via code review
