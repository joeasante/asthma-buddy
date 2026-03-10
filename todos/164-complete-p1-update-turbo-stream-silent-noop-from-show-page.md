---
status: pending
priority: p1
issue_id: "164"
tags: [code-review, turbo, show-pages, peak-flow]
dependencies: []
---

# update.turbo_stream Silently Fails When Edit Is Submitted from Show Page

## Problem Statement

`update.turbo_stream.erb` issues `turbo_stream.replace dom_id(@peak_flow_reading)` to replace the reading card in the index list. When a user edits a reading from the show page (not from the index), that card is not in the DOM. Turbo silently does nothing — no confirmation, no navigation, the user stays on the edit page seeing stale data. The HTML update path also currently redirects to `peak_flow_readings_path` (index), but after editing from a show page the user should return to the show page.

## Findings

The edit flow was built assuming the user always arrives from the index. The addition of a show page creates a second entry point for the edit action. When the edit form is submitted from the show page:

1. The turbo_stream response fires `turbo_stream.replace` targeting a DOM ID that does not exist on the show page.
2. Turbo silently ignores the missing target — no error, no navigation.
3. The user remains on the stale edit page with no feedback that the save succeeded.

The HTML fallback path (`format.html`) redirects to the index unconditionally, which is also wrong for the show-page origin case.

## Proposed Solutions

### Option A: Fix the HTML redirect to point to the show page

Add `format.html { redirect_to peak_flow_reading_path(@peak_flow_reading) }` to the update action's success branch, replacing the current index redirect. The turbo_stream replace is still useful for index-origin edits (where the card exists in the DOM), and the HTML redirect cleanly handles show-origin edits.

- Pros: Minimal change, no template logic required, correct behaviour for both origins
- Cons: turbo_stream path still silently no-ops when target is absent (not an error, just inert)
- Effort: Small
- Risk: Low

### Option B: Conditional redirect in the turbo_stream template

In `update.turbo_stream.erb`, add a conditional that checks whether the index card exists in the DOM; if not, redirect to the show page via `turbo_stream.action :redirect, peak_flow_reading_path(@peak_flow_reading)`.

- Pros: Handles the show-origin case entirely within Turbo, no HTML fallback required
- Cons: Template logic is harder to test, relies on Turbo's action :redirect which is less widely documented
- Effort: Small
- Risk: Medium

## Recommended Action

(leave blank — fill during triage)

## Technical Details

- Affected files:
  - app/views/peak_flow_readings/update.turbo_stream.erb
  - app/controllers/peak_flow_readings_controller.rb

## Acceptance Criteria

- [ ] After editing a reading from the show page, user is redirected to the show page with updated data visible
- [ ] After editing a reading from the index, the card is replaced in the list via turbo stream (no full page reload)
- [ ] Toast notification fires in both cases
- [ ] No silent no-op state is reachable by the user

## Work Log

- 2026-03-10: Created via code review

## Resources

- Code review of show pages + peak flow redesign
