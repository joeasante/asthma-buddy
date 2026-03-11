---
status: pending
priority: p1
issue_id: "248"
tags: [code-review, testing, rails, turbo-stream]
dependencies: ["247"]
---

# Missing Controller Tests for Update Action on Course Medications

## Problem Statement

The controller test suite has no tests verifying that PATCH on a course medication returns the `_course_medication` partial (or a non-course medication returns `_medication`). Without these tests, the regression in #247 was undetected and future regressions to the update stream will also go undetected.

## Findings

`test/controllers/settings/medications_controller_test.rb` tests cover: create (course + non-course), index split, archive boundary, adherence exclusion, and cross-user isolation. The `update` action has zero course-specific tests.

The bug in `update.turbo_stream.erb` (hardcoded `_medication` partial) is directly caused by this test gap.

## Proposed Solutions

### Option A — Add two targeted controller tests *(Recommended)*

```ruby
test "update course medication responds with course_medication partial" do
  course_med = medications(:alice_active_course)
  patch settings_medication_url(course_med),
    params: { medication: { name: "Updated Prednisolone" } },
    headers: { "Accept" => "text/vnd.turbo-stream.html" }

  assert_response :success
  assert_match "medication-badge--course", response.body
  assert_equal "Updated Prednisolone", course_med.reload.name
end

test "update non-course medication responds with medication partial" do
  patch settings_medication_url(@medication),
    params: { medication: { name: "Updated Ventolin" } },
    headers: { "Accept" => "text/vnd.turbo-stream.html" }

  assert_response :success
  assert_no_match "medication-badge--course", response.body
end
```

Pros: directly covers the regression, two clear test cases
Cons: none

## Recommended Action

Option A — add both tests after fixing #247.

## Technical Details

- **Affected file:** `test/controllers/settings/medications_controller_test.rb`
- **Depends on:** #247 (fix must land first so tests pass)

## Acceptance Criteria

- [ ] Test: PATCH on course medication → Turbo Stream contains `medication-badge--course`
- [ ] Test: PATCH on non-course medication → Turbo Stream does not contain `medication-badge--course`
- [ ] Both tests pass with #247 fix applied

## Work Log

- 2026-03-10: Identified during Phase 18 code review
