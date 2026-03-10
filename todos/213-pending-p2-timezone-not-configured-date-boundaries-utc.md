---
status: pending
priority: p2
issue_id: "213"
tags: [code-review, security, patient-safety, configuration, rails]
dependencies: []
---

# Application Timezone Not Configured — Date Boundaries Use UTC, May Cause Incorrect GINA Classifications

## Problem Statement

`config.time_zone` is commented out in `config/application.rb` (line 34). Rails defaults to UTC. All date boundary calculations in `RelieverUsageController` use `Date.current`, `beginning_of_day`, `end_of_day`, and `beginning_of_month` — these all resolve against UTC.

For a UK-targeted app (the GINA bands and "Speak to your GP" phrasing indicate a UK audience), a user in BST (UTC+1) logging a reliever dose at 11:30 PM British time logs it at 10:30 PM UTC. The `beginning_of_month.beginning_of_day` boundary (UTC midnight) may omit doses logged in the first hour of each month from a UK perspective, or count doses from the previous calendar month.

**Patient safety concern:** Incorrect dose counts produce incorrect GINA band classifications. A user with 6+ reliever uses in a month (requiring "Speak to your GP") could be shown "Well controlled" if the boundary excludes their late-evening doses.

## Findings

**Flagged by:** security-sentinel (P3 → upgraded to P2 due to patient safety implications)

**Location:** `config/application.rb` line 34 (commented out)

```ruby
# config.time_zone = "Central Time (US & Canada)"
```

**Affected query boundaries in `reliever_usage_controller.rb`:**
- `period_start.beginning_of_day` — UTC midnight, not user's midnight
- `Date.current.end_of_day` — UTC end of day
- `Date.current.beginning_of_month.beginning_of_day` — monthly window in UTC

**Broader impact:** Every controller that uses `Date.current` or date boundary helpers has this issue — `PeakFlowReadingsController`, `AdherenceController`, `DashboardController`, etc.

## Proposed Solutions

### Option A — Set `config.time_zone = "London"` (Recommended)
**Effort:** Small (config + audit) | **Risk:** Medium (affects all date queries)

```ruby
# config/application.rb
config.time_zone = "London"
```

Then audit `Date.current` usage across all controllers and models — replace with `Time.current.to_date` where timezone sensitivity matters. `Time.current` respects the configured zone; `Date.current` does not.

**High-risk locations to audit:**
- `RelieverUsageController` lines 23, 95, 73 (`Date.current`)
- `PeakFlowReadingsController` — similar date boundary queries
- Any `beginning_of_day`/`end_of_day` boundaries in queries

**Pros:** Correct date boundaries for UK users. Patient data integrity.
**Cons:** Small risk of changing existing query results — should test carefully against fixtures.

### Option B — Set timezone per-request using `Current` attributes
**Effort:** Larger | **Risk:** Higher

Store user's timezone preference in `Current.timezone`, apply per-request with `Time.use_zone`. Allows per-user timezone support eventually.

### Option C — Accept UTC (simplest, no patient safety fix)
**Effort:** None | **Risk:** Date boundary errors remain for non-UTC users

**Not recommended** for a medical app.

## Recommended Action

Option A. Set `config.time_zone = "London"` and replace `Date.current` with `Time.current.to_date` in all controller date boundary calculations. Run full test suite to catch regressions.

## Technical Details

- **Affected files:** `config/application.rb`, all controllers using `Date.current`
- **Test risk:** Fixtures use hardcoded dates — verify the test suite passes after the timezone change

## Acceptance Criteria

- [ ] `config.time_zone` is set to `"London"` (or appropriate target locale) in `application.rb`
- [ ] `Date.current` in `reliever_usage_controller.rb` replaced with `Time.current.to_date`
- [ ] Same replacement applied to other controllers that use date boundaries for queries
- [ ] All tests pass after the change

## Work Log

- 2026-03-10: Identified by security-sentinel. Upgraded to P2 due to patient safety implications in GINA classification.
