---
status: complete
priority: p2
issue_id: "037"
tags: [code-review, testing, api, json, authentication]
dependencies: []
---

# Zero JSON Test Coverage for Auth Controllers — Production Code Untested

## Problem Statement

All three auth controllers (`SessionsController`, `PasswordsController`, `RegistrationsController`) now respond to both HTML and JSON. Every existing controller test exercises only the HTML format. The JSON branches — which are the stated architectural priority for agent access — have zero test coverage. This allowed the `session_id` usability issue (#035) and user enumeration issue (#036) to reach review undetected.

## Findings

**Flagged by:** architecture-strategist (Medium), agent-native-reviewer (Observation 2)

**Location:** All tests in `test/controllers/`

```ruby
# test/controllers/sessions_controller_test.rb — all tests use HTML format only:
post session_path, params: { email_address: @user.email_address, password: "password123" }
# ^ no as: :json, no Accept header, no assertion on JSON body
```

**Missing coverage:**
- `POST /session` with `Accept: application/json` — success, wrong credentials, unverified, rate limit
- `DELETE /session` with `Accept: application/json` — success
- `POST /registration` with `Accept: application/json` — success, validation errors
- `POST /passwords` with `Accept: application/json` — success, unknown email
- `PATCH /passwords/:token` with `Accept: application/json` — success, invalid token, mismatched passwords
- `GET /email_verification/:token` with `Accept: application/json` — (after #034 is fixed)

## Proposed Solutions

### Solution A: Add JSON integration tests to existing test files (Recommended)
Add `as: :json` to existing test calls and assert on status codes and response body structure:

```ruby
test "POST /session with valid credentials returns 201 JSON" do
  post session_path,
    params: { email_address: @user.email_address, password: "password123" },
    as: :json
  assert_response :created
  json = response.parsed_body
  assert_includes json.keys, "message"
  refute_includes json.keys, "session_id"  # should not expose DB id
end

test "POST /session with wrong password returns 401 JSON" do
  post session_path,
    params: { email_address: @user.email_address, password: "wrong" },
    as: :json
  assert_response :unauthorized
  assert_equal "Invalid email address or password", response.parsed_body["error"]
end
```
- **Effort:** Medium (~30-40 lines across 3 test files)
- **Risk:** Low

### Solution B: Separate JSON integration test files
Create `test/integration/json_api/` namespace.
- **Effort:** Large
- **Risk:** Low

## Recommended Action

Solution A — add JSON test cases to existing controller test files.

## Technical Details

- **Files:** `test/controllers/sessions_controller_test.rb`, `test/controllers/passwords_controller_test.rb`, `test/controllers/registrations_controller_test.rb`
- `as: :json` sets `Content-Type: application/json` and `Accept: application/json` automatically in Rails integration tests.

## Acceptance Criteria

- [ ] `POST /session` has JSON tests: success (201), wrong credentials (401), unverified (401 after #036), rate limit (429)
- [ ] `DELETE /session` has JSON test: success (204)
- [ ] `POST /registration` has JSON tests: success (201), validation failure (422)
- [ ] `POST /passwords` has JSON test: success (200)
- [ ] `PATCH /passwords/:token` has JSON tests: success (200), invalid token (404), mismatch (422)
- [ ] All JSON tests assert on response body structure (key names and values)

## Work Log

- 2026-03-07: Created from second-pass code review. Flagged by architecture-strategist and agent-native-reviewer.
