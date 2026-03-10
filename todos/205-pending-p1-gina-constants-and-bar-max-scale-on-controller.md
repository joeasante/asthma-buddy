---
status: pending
priority: p1
issue_id: "205"
tags: [code-review, architecture, rails, convention-violation]
dependencies: []
---

# GINA Thresholds and `BAR_MAX_SCALE` Defined on Controller; View References Controller Constant

## Problem Statement

`GINA_REVIEW_THRESHOLD`, `GINA_URGENT_THRESHOLD`, `BAR_MAX_SCALE`, and `gina_band` are defined on `RelieverUsageController`. These are medical domain constants/logic that classify what a dose count means clinically — the same category as `PeakFlowReading::GREEN_ZONE_THRESHOLD` (line 9 of `peak_flow_reading.rb`), which correctly lives on the model. Controllers must not own domain constants.

The immediate consequence is worse: the view reaches directly into the controller class:

```erb
<%# app/views/reliever_usage/index.html.erb, line 80 %>
<% fill_pct = [(week[:uses] / RelieverUsageController::BAR_MAX_SCALE * 100).round, 100].min %>
```

This is the only place in the codebase where a view names a controller class. It creates a hard coupling: if the controller is renamed or the partial is used from another context, this raises `NameError` at runtime with no compile-time protection.

## Findings

**Flagged by:** kieran-rails-reviewer (P1), architecture-strategist (P1), pattern-recognition-specialist (P2), code-simplicity-reviewer (P1)

**Locations:**
- `app/controllers/reliever_usage_controller.rb` lines 4–6 (constants) and 111–119 (`gina_band` method)
- `app/views/reliever_usage/index.html.erb` line 80 (`RelieverUsageController::BAR_MAX_SCALE`)
- `app/views/reliever_usage/index.html.erb` line 124 (hardcoded `3` in prose)

**Precedent in this codebase:**
- `PeakFlowReading::GREEN_ZONE_THRESHOLD = 80` — model owns zone threshold
- `PeakFlowReading#compute_zone` — model owns zone classification logic
- `DashboardController` references `PeakFlowReading::GREEN_ZONE_THRESHOLD` — controller reads from model, not vice versa

**Forward risk:** Phase 19 (notifications) and any GP export will need to classify usage by GINA band. They will either duplicate magic numbers 3/6 or create a cross-layer controller dependency.

## Proposed Solutions

### Option A — Move to `DoseLog` model (Recommended)
**Effort:** Small | **Risk:** Low

```ruby
# app/models/dose_log.rb
GINA_REVIEW_THRESHOLD = 3
GINA_URGENT_THRESHOLD = 6

def self.gina_band(uses)
  if uses >= GINA_URGENT_THRESHOLD
    :urgent
  elsif uses >= GINA_REVIEW_THRESHOLD
    :review
  else
    :controlled
  end
end
```

Controller keeps `MONTHLY_CONTROL_TIERS` (presentation concerns are OK there) but references `DoseLog::GINA_REVIEW_THRESHOLD` for the numeric thresholds.

View fix: push `fill_pct` computation into `build_weekly_data` and add `:fill_pct` to the returned hash:
```ruby
fill_pct: [(uses / DoseLog::GINA_URGENT_THRESHOLD.to_f * 100).round, 100].min,
```
View becomes: `style="--bar-fill-height: <%= week[:fill_pct] %>%;"` — no controller reference.

Fix hardcoded `3` in view line 124: `<%= DoseLog::GINA_REVIEW_THRESHOLD %> or more reliever uses`.

**Pros:** Follows established pattern. Enables future reuse. Eliminates view-to-controller coupling.
**Cons:** Small refactor across 2 files.

### Option B — Instance variable assignment in controller
**Effort:** Smaller | **Risk:** Lower

Keep constants on controller but assign `@bar_max_scale` in `index`:
```ruby
@bar_max_scale = GINA_URGENT_THRESHOLD.to_f
```
View: `week[:uses] / @bar_max_scale` — no class reference.

**Pros:** Minimal change, removes the view-to-class coupling immediately.
**Cons:** Doesn't solve the domain-logic-on-controller problem. Thresholds still unavailable to other features.

## Recommended Action

Option A. Move `GINA_REVIEW_THRESHOLD`, `GINA_URGENT_THRESHOLD`, and `gina_band` to `DoseLog`. Keep `MONTHLY_CONTROL_TIERS` on the controller (it contains CSS strings — presentation concern). Push `fill_pct` into `build_weekly_data`.

## Technical Details

- **Affected files:** `app/models/dose_log.rb`, `app/controllers/reliever_usage_controller.rb`, `app/views/reliever_usage/index.html.erb`
- **Tests to update:** `test/controllers/reliever_usage_controller_test.rb` (no change needed — tests use HTTP, not constants directly)
- **Model test to add:** `test/models/dose_log_test.rb` — unit tests for `gina_band` and threshold values

## Acceptance Criteria

- [ ] `DoseLog::GINA_REVIEW_THRESHOLD` and `DoseLog::GINA_URGENT_THRESHOLD` exist and equal 3 and 6 respectively
- [ ] `DoseLog.gina_band(uses)` returns `:controlled`, `:review`, or `:urgent` correctly
- [ ] `RelieverUsageController::BAR_MAX_SCALE` is deleted
- [ ] View no longer references `RelieverUsageController` by name
- [ ] Unit tests for `gina_band` added to `dose_log_test.rb`
- [ ] All 367 tests still pass

## Work Log

- 2026-03-10: Identified by code review. Multiple agents flagged view-to-controller coupling as hard convention violation.

## Resources

- PR context: Phase 15.1 Reliever Usage History
- Precedent: `app/models/peak_flow_reading.rb` lines 9-10 (zone threshold constants on model)
- Architecture reviewer: `app/services/adherence_calculator.rb` pattern for future calculator extraction
