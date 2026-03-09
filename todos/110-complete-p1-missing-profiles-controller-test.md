---
status: pending
priority: p1
issue_id: "110"
tags: [code-review, testing, rails, security, profiles]
dependencies: []
---

# No `profiles_controller_test.rb` — password change and profile update completely untested

## Problem Statement

`ProfilesController` is new and introduces the most security-sensitive flows in the app: password change with current-password verification, email address update, and avatar upload. There is no `test/controllers/profiles_controller_test.rb`. The net test coverage for these flows is zero. The old `settings_controller_test.rb` had 14 tests covering this logic; those were removed and replaced with 3 redirect-only tests. The replacement controller has no tests at all.

## Findings

- `test/controllers/profiles_controller_test.rb` — does not exist (confirmed via directory listing)
- `app/controllers/profiles_controller.rb` — `update` handles password auth failure branch, validation failure branch, success branch; none tested
- `app/controllers/profiles_controller.rb:update_personal_best` — no tests
- Pattern: every other controller with write actions has a test file (`symptom_logs_controller_test.rb`, `peak_flow_readings_controller_test.rb`, `sessions_controller_test.rb`, `registrations_controller_test.rb`)

## Proposed Solutions

### Option A: Create profiles_controller_test.rb (Required)

Minimum test cases:
```ruby
class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  test "show renders profile page" do ...end
  test "update with valid params updates profile" do ...end
  test "update with invalid params re-renders show" do ...end
  test "update password with correct current password succeeds" do ...end
  test "update password with wrong current password fails" do ...end
  test "update personal best saves record" do ...end
  test "update personal best with invalid value fails" do ...end
  test "unauthenticated user is redirected from profile" do ...end
  test "show returns JSON when requested" do ...end  # agent-native
  test "update_personal_best returns JSON when requested" do ...end  # agent-native
end
```

**Effort:** Medium | **Risk:** Low

## Recommended Action

Option A — non-negotiable. Security-sensitive controller with no tests.

## Technical Details

- **Affected files:** `test/controllers/profiles_controller_test.rb` (new file)
- **Fixture dependency:** `users(:verified_user)` fixture exists in `test/fixtures/users.yml`

## Acceptance Criteria

- [ ] `test/controllers/profiles_controller_test.rb` exists
- [ ] Covers: show (HTML + JSON), update success, update validation failure, password change success/failure, personal best update, unauthenticated access
- [ ] All tests pass with `bin/rails test test/controllers/profiles_controller_test.rb`

## Work Log

- 2026-03-08: Identified by kieran-rails-reviewer and pattern-recognition-specialist during PR review
