---
status: pending
priority: p3
issue_id: "301"
tags: [code-review, rails, testing, routes, preventer-history]
dependencies: []
---

# No route test verifying /adherence → /preventer_history 301 redirect

## Problem Statement
`config/routes.rb` includes `get "adherence", to: redirect("/preventer_history")` to maintain backward compatibility after the AdherenceController → PreventerHistoryController rename. The redirect is present but has no test verifying it returns 301 and points to the correct destination. If the route is accidentally removed or changed, no test will catch it, and any user with a bookmarked `/adherence` URL will hit a 404 silently.

## Findings
**Flagged by:** architecture-strategist

**File:** `config/routes.rb` — `get "adherence", to: redirect("/preventer_history")`

No corresponding test in `test/controllers/preventer_history_controller_test.rb` or a dedicated routes test file.

## Proposed Solutions
### Option A — Add a request test
```ruby
test "GET /adherence redirects permanently to /preventer_history" do
  sign_in_as users(:verified_user)
  get "/adherence"
  assert_redirected_to "/preventer_history"
  assert_response :moved_permanently
end
```
**Effort:** Trivial.

## Recommended Action

## Technical Details
- **File:** `config/routes.rb` and `test/controllers/preventer_history_controller_test.rb`

## Acceptance Criteria
- [ ] Test asserting `GET /adherence` returns 301 to `/preventer_history`

## Work Log
- 2026-03-12: Code review finding — architecture-strategist

## Resources
- Branch: dev
- Related: todos/277-* (adherence redirect was the acceptance criteria)
