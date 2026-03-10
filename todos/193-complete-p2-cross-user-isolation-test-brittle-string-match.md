---
status: complete
priority: p2
issue_id: "193"
tags: [code-review, testing, security, phase-15-1]
dependencies: []
---

# Cross-User Isolation Test Uses Brittle Hard-Coded String Match

## Problem Statement
The cross-user isolation test (`reliever_usage_controller_test.rb:49-55`) asserts `assert_no_match(/Salbutamol/i, response.body)`. This test passes vacuously if Bob's medication is renamed in the fixture, and does not structurally verify that User A's queries cannot return User B's data. A regression removing the `Current.user` scope from the controller would not be caught. The test proves string absence, not data isolation.

## Findings
- **File:** `test/controllers/reliever_usage_controller_test.rb:49-55`
- Hard-coded medication name "Salbutamol" — if fixture changes, test silently passes regardless of isolation
- Does not assert from Bob's perspective that Alice's data is absent
- Does not verify the query-level isolation that `Current.user` scoping provides
- Security agent rated this P2; Rails reviewer rated P2

## Proposed Solutions

### Option A (Recommended): Test from second user's perspective
```ruby
test "index does not expose another user's reliever data" do
  alice_med_names = @user.medications.where(medication_type: :reliever).pluck(:name)
  assert alice_med_names.any?, "Need alice to have relievers for this test to be meaningful"

  sign_out
  sign_in_as users(:other_user)  # or users(:bob) depending on fixture name
  get reliever_usage_url
  assert_response :success

  alice_med_names.each do |name|
    assert_no_match(/#{Regexp.escape(name)}/i, response.body)
  end
end
```
- Effort: Small
- Risk: None — uses fixture data dynamically, not hard-coded strings

### Option B: Keep current test but add fixture-name lookup
Replace `/Salbutamol/i` with a dynamic lookup from the `bob_reliever` fixture: `medications(:bob_reliever).name`. Fragile fixture coupling remains but at least follows the data.
- Effort: Very small
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: `test/controllers/reliever_usage_controller_test.rb:49-55`

## Acceptance Criteria
- [ ] Isolation test uses dynamically derived medication names from fixtures, not hard-coded strings
- [ ] Test fails if `Current.user` scope is removed from the controller
- [ ] All tests pass

## Work Log
- 2026-03-10: Identified by security-sentinel and kieran-rails-reviewer in Phase 15.1 review
