---
status: complete
priority: p1
issue_id: "271"
tags: [code-review, rails, agent-native, api, dashboard]
dependencies: []
---

# DashboardController#index has no JSON API

## Problem Statement

`DashboardController#index` computes ~20 data points (today's best reading, week stats, chart data, active illness, low stock medications, preventer adherence, reliever medications, recent entries) but has no `respond_to` block. The `check_onboarding` guard already has a `format.json` branch — signalling the JSON path was planned but never completed.

An agent cannot retrieve the user's current asthma status at a glance. Every piece of data requires hitting multiple separate endpoints, making the app unusable for automated healthcare workflows.

## Findings

- **File:** `app/controllers/dashboard_controller.rb` — no `respond_to` in `#index`
- **Agent:** agent-native-reviewer
- The `check_onboarding` guard at the bottom of the controller already handles `format.json` with a proper `{ error: "onboarding_required" }` response — the intent to support JSON was clearly there
- All data is already assembled as Ruby objects/hashes; serialisation is straightforward

## Proposed Solutions

### Option A — Add `format.json` to `#index` (Recommended)

Add a `respond_to` block. Expose at minimum:
- `todays_best_reading` (value, zone, zone_pct)
- `week_avg`, `week_avg_zone`, `week_reading_count`, `week_symptom_count`
- `active_illness` (id, recorded_at)
- `low_stock_medications` (array with id, name, days_remaining)
- `preventer_adherence` (array per medication with today's status)
- `chart_data` (already a plain hash array — can be included as-is)

**Pros:** Complete parity. Follows existing pattern.
**Effort:** Small–Medium
**Risk:** Low

### Option B — Separate summary endpoint

`GET /dashboard/summary.json`

**Pros:** Clean.
**Cons:** Diverges from RESTful convention used everywhere else.
**Effort:** Small
**Risk:** Low

## Recommended Action

Option A.

## Technical Details

- **Affected files:** `app/controllers/dashboard_controller.rb`
- **Pattern to follow:** `app/controllers/health_events_controller.rb` — has `health_event_json` helper

## Acceptance Criteria

- [ ] `GET /dashboard.json` returns 200
- [ ] Response includes today's best reading with zone
- [ ] Response includes week stats
- [ ] Response includes active illness if present (nil otherwise)
- [ ] Response includes low stock medications array
- [ ] Controller test covers the JSON path with and without onboarding complete

## Work Log

- 2026-03-11: Identified by agent-native-reviewer during code review of dev branch
