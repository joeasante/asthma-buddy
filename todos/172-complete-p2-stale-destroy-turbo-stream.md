---
status: pending
priority: p2
issue_id: "172"
tags: [code-review, turbo, dead-code, peak-flow]
dependencies: []
---

# destroy.turbo_stream.erb Comment and Remove Target Are Stale After Index Redesign

## Problem Statement
destroy.turbo_stream.erb still says "Remove the table row" and issues `turbo_stream.remove dom_id(@peak_flow_reading)`. But (a) there is no table any more — the index is a grouped card list, and (b) the destroy action is currently unreachable from any UI path since neither the show page nor the edit page has a delete button (see todo #165). When destroy IS eventually called, it will be from the show page where the index card does not exist in the DOM. The `turbo_stream.remove` is a permanent no-op in the current architecture. The stale comment is actively misleading.

## Proposed Solutions

### Option A
Remove the stale `turbo_stream.remove` line and update the template to only emit a toast. The destroy action HTML path should redirect to the index — the card is gone and the user should return to the list.
- Effort: Small
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: app/views/peak_flow_readings/destroy.turbo_stream.erb, app/controllers/peak_flow_readings_controller.rb (destroy HTML path should redirect to index)

## Acceptance Criteria
- [ ] destroy.turbo_stream.erb no longer contains `turbo_stream.remove dom_id(@peak_flow_reading)`
- [ ] Stale "Remove the table row" comment is deleted
- [ ] destroy.turbo_stream.erb emits only a toast notification
- [ ] destroy HTML path in the controller redirects to the index
- [ ] No regression in destroy behaviour when triggered

## Work Log
- 2026-03-10: Created via code review
