---
status: pending
priority: p2
issue_id: "099"
tags: [code-review, rails, architecture, peak-flow, pagination]
dependencies: []
---

# Pagination arithmetic inlined in `index` controller — `PeakFlowReading` missing `.paginate` model method

## Problem Statement

The pagination arithmetic (`COUNT → total_pages → page clamping → OFFSET/LIMIT`) is duplicated inline in the `PeakFlowReadingsController#index` action. `SymptomLog` encapsulates the same arithmetic as `def self.paginate(page:, per_page: 25)`. `PeakFlowReading` has no equivalent. The magic number `25` (per-page count) appears hardcoded in the controller, creating a single point of inconsistency if the page size ever changes.

This is a separation-of-concerns violation: pagination slicing logic belongs in the model layer.

## Findings

**Flagged by:** architecture-strategist (P2), pattern-recognition-specialist (P2-A), performance-oracle (P2)

**Location:** `app/controllers/peak_flow_readings_controller.rb:53-55`

```ruby
@total_pages  = [ (base_relation.count.to_f / 25).ceil, 1 ].max
@current_page = [ [ params[:page].to_i, 1 ].max, @total_pages ].min
@peak_flow_readings = base_relation.offset((@current_page - 1) * 25).limit(25)
```

Reference pattern (`SymptomLog`):
```ruby
# model
def self.paginate(page:, per_page: 25)
  page        = [page.to_i, 1].max
  total       = count
  total_pages = [(total.to_f / per_page).ceil, 1].max
  page        = [page, total_pages].min
  records     = offset((page - 1) * per_page).limit(per_page)
  [records, total_pages, page]
end

# controller
@peak_flow_readings, @total_pages, @current_page = base_relation.paginate(page: params[:page])
```

## Proposed Solutions

### Option A: Add `.paginate` to `PeakFlowReading` (Recommended)

Mirror `SymptomLog.paginate` exactly. The controller then becomes a one-liner for pagination.

```ruby
# app/models/peak_flow_reading.rb
def self.paginate(page:, per_page: 25)
  page        = [page.to_i, 1].max
  total       = count
  total_pages = [(total.to_f / per_page).ceil, 1].max
  page        = [page, total_pages].min
  records     = offset((page - 1) * per_page).limit(per_page)
  [records, total_pages, page]
end
```

- **Pros:** Full parity with SymptomLog; model unit-testable; controller is clean; single per_page constant
- **Effort:** Small
- **Risk:** None

## Recommended Action

Option A. Also consider extracting a shared `Paginatable` concern if a third resource needs pagination.

## Technical Details

- **Affected files:** `app/models/peak_flow_reading.rb`, `app/controllers/peak_flow_readings_controller.rb`

## Acceptance Criteria

- [ ] `PeakFlowReading.paginate` exists and is unit-tested
- [ ] Controller `index` uses `base_relation.paginate(page: params[:page])` — no inline arithmetic
- [ ] Page clamping, total_pages, and OFFSET logic match existing behavior
- [ ] All 170 existing tests pass

## Work Log

- 2026-03-07: Identified during Phase 7 code review
