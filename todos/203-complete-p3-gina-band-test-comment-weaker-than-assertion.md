---
status: complete
priority: p3
issue_id: "203"
tags: [code-review, testing, clarity, phase-15-1]
dependencies: []
---

# GINA Band Test Comment Describes Stronger Assertion Than Actually Made

## Problem Statement
`test "index renders GINA band classes on bar fills"` (line 95–100 of the test file) has a comment claiming "we have fixtures with 4 uses in one week (review band) and 7 in another (urgent band)" — implying the test verifies specific band classes are present. But the assertions only check `assert_select ".reliever-bar-fill"` and `assert_select "[class*='reliever-bar-fill--']"`. Any bar at all satisfies these, regardless of which bands are present. The comment sets expectations the assertions don't fulfil.

## Findings
- **File:** `test/controllers/reliever_usage_controller_test.rb:95-100`
- Comment says "review band" and "urgent band" fixtures exist — true
- Assertions check generic class presence — does not verify specific band assignment
- Rails reviewer flagged this as P3

## Proposed Solutions

### Option A (Recommended): Strengthen assertions to match the comment
```ruby
# Fixtures create a review-band week and an urgent-band week
assert_select ".reliever-bar-fill--review"
assert_select ".reliever-bar-fill--urgent"
assert_select ".reliever-bar-fill--controlled"  # current week has 2 uses
```
- Effort: Small
- Risk: Low — may fail if fixture dates fall on week boundaries edge cases; adjust if needed

### Option B: Rewrite comment to accurately describe what is tested
```ruby
# Verifies that at least one bar fill with a GINA band modifier class is rendered.
# Specific band classes are not asserted here — they depend on fixture timing.
assert_select ".reliever-bar-fill"
assert_select "[class*='reliever-bar-fill--']"
```
- Effort: Minimal
- Risk: None

## Recommended Action

## Technical Details
- Affected files: `test/controllers/reliever_usage_controller_test.rb:95-100`

## Acceptance Criteria
- [ ] Comment accurately describes what the test asserts
- [ ] If assertions are strengthened, they pass reliably regardless of current date

## Work Log
- 2026-03-10: Identified by kieran-rails-reviewer in Phase 15.1 review
