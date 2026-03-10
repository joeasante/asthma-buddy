---
status: pending
priority: p1
issue_id: "165"
tags: [code-review, peak-flow, show-pages, ux]
dependencies: []
---

# No UI Path to Delete a Peak Flow Reading After Index Redesign

## Problem Statement

The table redesign removed the inline Delete button from the index list. The show page has only an "Edit" button. The edit form (_form.html.erb) has no delete action. The destroy controller action exists and is correctly implemented, but it is unreachable from any rendered link or button in the current view layer. Users who entered an erroneous reading (e.g., a coughing fit during measurement) have no way to remove it through the UI. For a medical data application this is a basic usability requirement.

## Findings

The `destroy` action in `PeakFlowReadingsController` is correctly authorised and scoped to the current user. It responds to DELETE requests and is covered by routing. However, no view currently renders a link or button that issues that request. The index redesign that introduced the card layout removed the previous delete affordance without providing a replacement. The show page was added but includes only an edit link.

`destroy.turbo_stream.erb` issues `turbo_stream.remove dom_id(@peak_flow_reading)` targeting the index card. When destroy is eventually triggered from the show page, that target will not exist — the stream response will be a no-op. This must be handled alongside the delete button addition.

## Proposed Solutions

### Option A: Add a Delete button to the show page

Add a `button_to` with `method: :delete` and `data: { turbo_confirm: "Delete this reading? This can't be undone." }` to the show page, styled as a destructive secondary action. After destroy, redirect to the index page with a "Reading deleted." toast. Handle the `destroy.turbo_stream.erb` no-op by either updating the stream to perform a redirect or relying on the HTML fallback (index redirect) for show-page-origin destroys.

- Pros: Correct placement (destructive actions belong on the detail view, not the list), low implementation effort, confirm dialog prevents accidents
- Cons: destroy.turbo_stream.erb still targets a non-existent card when coming from the show page; needs cleanup or a conditional response
- Effort: Small
- Risk: Low

## Recommended Action

(leave blank — fill during triage)

## Technical Details

- Affected files:
  - app/views/peak_flow_readings/show.html.erb
  - app/views/peak_flow_readings/destroy.turbo_stream.erb

## Acceptance Criteria

- [ ] Delete button is visible on the show page
- [ ] Clicking Delete triggers a confirmation dialog before submitting
- [ ] Confirmed delete removes the reading from the database
- [ ] After deletion, user is redirected to the index with a "Reading deleted." toast
- [ ] No orphaned DOM targets or silent no-ops in the turbo_stream destroy response

## Work Log

- 2026-03-10: Created via code review

## Resources

- Code review of show pages + peak flow redesign
