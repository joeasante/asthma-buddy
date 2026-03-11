---
status: complete
priority: p3
issue_id: "287"
tags: [code-review, rails, performance, peak-flow, api]
dependencies: []
---

# Eyebrow queries in `PeakFlowReadingsController#destroy` not guarded by format check

## Problem Statement

`PeakFlowReadingsController#destroy` calls `set_page_header_vars` (or equivalent) which runs the eyebrow stat queries (`last_reading`, `month_count`) before the `respond_to` block. For JSON API clients deleting a peak flow reading, these queries execute and then their results are never used — the JSON response returns only a 204 or the deleted record, not eyebrow stats.

This is a minor wasted query per JSON delete request, but it is inconsistent with the principle of only computing what the response format needs.

## Findings

- **File:** `app/controllers/peak_flow_readings_controller.rb` — `#destroy` action
- **Agent:** performance-oracle

## Proposed Solutions

### Option A — Move eyebrow queries inside the Turbo Stream / HTML branch (Recommended)

```ruby
def destroy
  @peak_flow_reading.destroy!
  respond_to do |format|
    format.turbo_stream do
      set_page_header_vars  # only computed when needed
      render :destroy
    end
    format.html { redirect_to peak_flow_readings_path }
    format.json { head :no_content }
  end
end
```

**Effort:** Small
**Risk:** None

### Option B — Leave as-is

**Pros:** No change.
**Cons:** Unnecessary queries for JSON clients.
**Effort:** None
**Risk:** None (performance only, minor)

## Recommended Action

Option A.

## Technical Details

- **Affected file:** `app/controllers/peak_flow_readings_controller.rb`

## Acceptance Criteria

- [ ] JSON DELETE `/peak-flow-readings/:id.json` does not fire eyebrow stat queries
- [ ] Turbo Stream destroy response still includes updated eyebrow stats

## Work Log

- 2026-03-11: Identified by performance-oracle during code review of dev branch
