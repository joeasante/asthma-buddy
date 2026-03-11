---
status: complete
priority: p3
issue_id: "218"
tags: [code-review, rails, maintainability, reliever-usage]
dependencies: ["205"]
---

# Hardcoded GINA Values in View Legend and Correlation Prose Will Drift if Thresholds Change

## Problem Statement

Two places in the view hardcode numeric GINA thresholds as raw strings:

**1. GINA legend (lines 99–101):**
```erb
<span class="dash-zone-legend-item dash-zone-legend-item--green">0&ndash;2 Controlled</span>
<span class="dash-zone-legend-item dash-zone-legend-item--yellow">3&ndash;5 Review</span>
<span class="dash-zone-legend-item dash-zone-legend-item--red">6+ Speak to GP</span>
```

**2. Correlation prose (line 124):**
```erb
On weeks with 3 or more reliever uses, your average peak flow was
```

Both hardcode the values 2, 3, 5, 6 which come from `GINA_REVIEW_THRESHOLD = 3` and `GINA_URGENT_THRESHOLD = 6`. If the thresholds change, these strings will silently diverge.

Blocked by Todo 205 (which moves the constants to `DoseLog`).

## Findings

**Flagged by:** architecture-strategist (P3), code-simplicity-reviewer (via `gina_bands` JSON YAGNI note)

**Location:** `app/views/reliever_usage/index.html.erb` lines 99–101 and 124

## Proposed Solutions

### Option A — Reference constants in the view (Recommended, after Todo 205)
**Effort:** Trivial (after constants move to DoseLog)

```erb
<%# Legend %>
<span ...>0&ndash;<%= DoseLog::GINA_REVIEW_THRESHOLD - 1 %> Controlled</span>
<span ...><%= DoseLog::GINA_REVIEW_THRESHOLD %>&ndash;<%= DoseLog::GINA_URGENT_THRESHOLD - 1 %> Review</span>
<span ...><%= DoseLog::GINA_URGENT_THRESHOLD %>+ Speak to GP</span>

<%# Prose %>
On weeks with <%= DoseLog::GINA_REVIEW_THRESHOLD %> or more reliever uses, ...
```

### Option B — Keep hardcoded (GINA thresholds are unlikely to change)
**Effort:** None

GINA guidelines have used 3/6 for decades. The risk of drift is very low.

## Recommended Action

Option A, but only after Todo 205 is resolved. Bundle these changes in the same PR that moves constants to `DoseLog`. This is a one-liner per location.

**Dependency:** This todo is blocked by Todo 205 (GINA constants on DoseLog).

## Technical Details

- **Affected files:** `app/views/reliever_usage/index.html.erb`
- **Blocked by:** Todo 205

## Acceptance Criteria

- [ ] GINA legend values derived from `DoseLog::GINA_*_THRESHOLD` constants
- [ ] Correlation prose `3` replaced with `<%= DoseLog::GINA_REVIEW_THRESHOLD %>`
- [ ] Visual output identical to current

## Work Log

- 2026-03-10: Identified by architecture-strategist. Low priority — bundle with Todo 205.
