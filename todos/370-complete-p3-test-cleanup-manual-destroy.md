---
status: complete
priority: p3
issue_id: 370
tags: [code-review, testing]
dependencies: []
---

## Problem Statement

Multiple tests manually create records and call `.destroy` at the end of the test for cleanup. Minitest transactional tests handle cleanup automatically via transaction rollback. Manual destroy is fragile — if an assertion fails before the destroy call, the record leaks and can affect other tests.

## Findings

The pattern of manual `.destroy` calls at the end of tests is unnecessary when using transactional test fixtures (the Rails default). Any records created during a test are automatically rolled back when the test transaction ends, regardless of whether the test passes or fails.

## Proposed Solutions

- Remove manual `.destroy` calls from test teardown and test method bodies.
- Verify that `self.use_transactional_tests` is not set to `false` in these test classes.
- If any tests genuinely need non-transactional behavior, document why.

## Technical Details

**Affected files:** test/controllers/appointment_summaries_controller_test.rb, test/controllers/dashboard_controller_test.rb

## Acceptance Criteria

- [ ] Manual `.destroy` cleanup calls removed from tests
- [ ] Transactional test behavior confirmed as active for affected test classes
- [ ] All affected tests continue to pass without manual cleanup
- [ ] No test pollution or leaked records after changes
