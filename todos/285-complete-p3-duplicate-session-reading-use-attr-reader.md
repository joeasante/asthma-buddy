---
status: complete
priority: p3
issue_id: "285"
tags: [code-review, rails, ruby, models, peak-flow, quality]
dependencies: []
---

# `duplicate_session_reading` method body should be `attr_reader`

## Problem Statement

`PeakFlowReading` exposes a `duplicate_session_reading` public method that simply returns `@duplicate_reading`. This is the pattern `attr_reader` was built for. Using a hand-written method body is more verbose and obscures intent.

## Findings

- **File:** `app/models/peak_flow_reading.rb` — `duplicate_session_reading` method
- **Agent:** code-simplicity-reviewer

## Proposed Solutions

### Option A — Replace with `attr_reader` (Recommended)

```ruby
# Before
def duplicate_session_reading
  @duplicate_reading
end

# After
attr_reader :duplicate_session_reading
```

If the ivar is named `@duplicate_reading` but the public reader is `duplicate_session_reading`, use `attr_reader` with an alias or rename the ivar to match.

**Effort:** Trivial
**Risk:** None

### Option B — Leave as-is

**Pros:** No change.
**Cons:** Unnecessary method body for a plain ivar reader.

## Recommended Action

Option A.

## Technical Details

- **Affected file:** `app/models/peak_flow_reading.rb`

## Acceptance Criteria

- [ ] `attr_reader :duplicate_session_reading` (or equivalent) replaces the hand-written method
- [ ] All callers (`@peak_flow_reading.duplicate_session_reading`) continue to work

## Work Log

- 2026-03-11: Identified by code-simplicity-reviewer during code review of dev branch
