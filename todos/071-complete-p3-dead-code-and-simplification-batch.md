---
status: pending
priority: p3
issue_id: "071"
tags: [code-review, simplicity, quality, rails]
dependencies: []
---

# Dead Code and Simplification Batch — Phase 6 Cleanup

## Problem Statement

Three small clean-up items identified by the simplicity reviewer and architecture strategist, grouped for a single small PR:

1. `include ActionView::RecordIdentifier` in `PeakFlowReadingsController` — never used
2. `assign_zone` private method — one-liner wrapper for `compute_zone`, adds indirection without benefit
3. Redundant prose comments on model methods that describe exactly what the code says

## Findings

**Flagged by:** code-simplicity-reviewer, architecture-strategist, pattern-recognition-specialist

### Item 1: Dead include
```ruby
# app/controllers/peak_flow_readings_controller.rb:4
class PeakFlowReadingsController < ApplicationController
  include ActionView::RecordIdentifier  # provides dom_id/dom_class — never called here
```

`SymptomLogsController` uses `dom_id(@symptom_log)` in its update/destroy turbo stream handlers — that's why it needs the include. `PeakFlowReadingsController` uses a hardcoded string `"peak_flow_reading_form"`, never `dom_id`. The include is cargo-culted from the sibling controller.

**Risk if kept:** When Phase 7 adds edit/update/destroy actions, developers may assume `dom_id` is already available (it is, via the include) without understanding why, making it harder to notice if the include is later removed.

### Item 2: `assign_zone` wrapper
```ruby
# app/models/peak_flow_reading.rb:39-47
before_save :assign_zone

private

def assign_zone
  self.zone = compute_zone
end
```

`assign_zone` exists only to be named in `before_save`. Replace with:
```ruby
before_save { self.zone = compute_zone }
```

`compute_zone` remains public and directly testable. No test changes needed — the test suite calls `compute_zone` directly, not `assign_zone`.

### Item 3: Redundant comments
```ruby
# Returns the personal best value for this user at the time of this reading.
# Looks for the most recent PersonalBestRecord with recorded_at <= self.recorded_at.
# Returns nil if no personal best exists before this reading.
def personal_best_at_reading_time

# Compute zone from value vs personal best at reading time.
# Returns :green, :yellow, :red, or nil (no personal best).
def compute_zone
```

Both comment blocks describe exactly what the code below them does. `personal_best_at_reading_time` is self-documenting. `compute_zone` is equally clear. Removing these reduces maintenance surface (comments that can go stale) with no information loss.

## Proposed Solution

Three edits across two files:

```ruby
# BEFORE (peak_flow_readings_controller.rb)
class PeakFlowReadingsController < ApplicationController
  include ActionView::RecordIdentifier

# AFTER
class PeakFlowReadingsController < ApplicationController
```

```ruby
# BEFORE (peak_flow_reading.rb)
  before_save :assign_zone

  private

  def assign_zone
    self.zone = compute_zone
  end

# AFTER
  before_save { self.zone = compute_zone }

  private
```

Remove the two comment blocks (6 lines).

**Effort:** XSmall (~10 minutes)
**Risk:** Zero

## Acceptance Criteria

- [ ] `include ActionView::RecordIdentifier` removed from `PeakFlowReadingsController`
- [ ] `assign_zone` private method replaced with inline `before_save` block
- [ ] Redundant prose comments removed from `peak_flow_reading.rb`
- [ ] All 142 existing tests still pass

## Work Log

- 2026-03-07: Identified by code-simplicity-reviewer and architecture-strategist during Phase 6 code review
