---
status: pending
priority: p2
issue_id: "098"
tags: [code-review, rails, architecture, dry]
dependencies: []
---

# `include ActionView::RecordIdentifier` duplicated in two controllers — belongs in ApplicationController

## Problem Statement

`PeakFlowReadingsController` and `SymptomLogsController` both independently include `ActionView::RecordIdentifier` to use `dom_id` in controller context (Turbo Stream responses, rate limit lambdas). The test file also includes it. As more Turbo-enabled controllers are added, this include will repeat. Moving it to `ApplicationController` removes duplication with no side effects — the module is lightweight and adds only `dom_id` and `dom_class`.

## Findings

**Flagged by:** architecture-strategist (P2), pattern-recognition-specialist (P2)

**Locations:**
- `app/controllers/symptom_logs_controller.rb:4`
- `app/controllers/peak_flow_readings_controller.rb:4`
- `test/controllers/peak_flow_readings_controller_test.rb:6` (also in test)

```ruby
# Both controllers have:
include ActionView::RecordIdentifier
```

## Proposed Solutions

### Option A: Move to ApplicationController (Recommended)

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include ActionView::RecordIdentifier
  # ...
end
```

Remove the `include` line from both resource controllers. The test file may also be able to drop its include if the helper is inherited.

- **Pros:** Single source of truth; automatic for all future controllers; no functional change
- **Effort:** Tiny (3 line removals + 1 line addition)
- **Risk:** None — the module is additive only

## Recommended Action

Option A.

## Technical Details

- **Affected files:** `app/controllers/application_controller.rb`, `app/controllers/symptom_logs_controller.rb`, `app/controllers/peak_flow_readings_controller.rb`

## Acceptance Criteria

- [ ] `include ActionView::RecordIdentifier` exists only in `ApplicationController`
- [ ] Both resource controllers no longer have the include line
- [ ] All 170 tests pass (no dom_id breakage)

## Work Log

- 2026-03-07: Identified during Phase 7 code review
