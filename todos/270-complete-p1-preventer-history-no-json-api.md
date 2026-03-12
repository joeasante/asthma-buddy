---
status: complete
priority: p1
issue_id: "270"
tags: [code-review, rails, agent-native, api]
dependencies: []
---

# PreventerHistoryController has no JSON API

## Problem Statement

`PreventerHistoryController#index` builds a rich `@adherence_history` structure (per-medication, per-day adherence results over 7 or 30 days) but has no `respond_to` block at all. The controller renders an HTML view only. This is the only page in the app that shows adherence trends over time and it is completely inaccessible to any non-browser client.

This is the most clinically important data in the app — adherence trends over time — and it has zero API surface.

## Findings

- **File:** `app/controllers/preventer_history_controller.rb` — no `respond_to` block
- **Agent:** agent-native-reviewer
- Every other data controller in the codebase (peak flow, symptoms, health events, medications, notifications) has a `format.json` branch. This is the only exception.
- An agent answering "how well did the user take their preventer this week?" cannot get this data.

## Proposed Solutions

### Option A — Add `format.json` to `#index` (Recommended)
Add a `respond_to` block to the index action. Serialise the `@adherence_history` structure: per medication — `medication_id`, `name`, `doses_per_day`, and `days_data` array with `date`, `taken`, `required`, `status`. Also expose `@period` and header stats.

**Pros:** Complete parity. Follows existing pattern. Low risk.
**Cons:** Need to define the serialisation shape carefully.
**Effort:** Small
**Risk:** Low

### Option B — Add a dedicated JSON endpoint
Create a separate `GET /settings/medications/:id/adherence` endpoint.

**Pros:** Clean separation.
**Cons:** Over-engineered for what's needed. Diverges from existing pattern.
**Effort:** Medium
**Risk:** Low

## Recommended Action

Option A.

## Technical Details

- **Affected files:** `app/controllers/preventer_history_controller.rb`
- **Pattern to follow:** `app/controllers/peak_flow_readings_controller.rb#index` — has both HTML and JSON branches

## Acceptance Criteria

- [x] `GET /preventer_history.json` returns 200 with adherence data
- [x] Response includes per-medication adherence for the selected period
- [x] Response includes `period`, `days_taken`, `days_elapsed` header stats
- [x] Controller test covers the JSON path

## Work Log

- 2026-03-11: Identified by agent-native-reviewer during code review of dev branch
- 2026-03-11: Resolved — added respond_to block with format.json serialising adherence_history; 4 new JSON controller tests added; commit 5ea1b92
