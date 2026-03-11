---
status: complete
priority: p3
issue_id: "217"
tags: [code-review, testing, rails, reliever-usage]
dependencies: []
---

# JSON Controller Test Asserts Key Presence Only — Not Item Shape or Band Values

## Problem Statement

The JSON test in `test/controllers/reliever_usage_controller_test.rb` verifies top-level key presence but not:
- The shape of `weekly_data` items (missing `week_start`, `week_end`, `uses`, `band`, `label` checks)
- That `band` values are from the expected set (`"controlled"`, `"review"`, `"urgent"`)
- The correlation object structure when present
- The `gina_bands` values

Any regression in `reliever_usage_json` that changes the serialised key names or drops fields would pass the current test.

## Findings

**Flagged by:** kieran-rails-reviewer (P3)

**Location:** `test/controllers/reliever_usage_controller_test.rb` lines 104–114

```ruby
test "index responds to JSON format" do
  get reliever_usage_url, as: :json
  assert_response :success
  json = response.parsed_body
  assert json.key?("weekly_data"), "JSON response must include weekly_data"
  assert json.key?("monthly_uses"), "JSON response must include monthly_uses"
  assert json.key?("gina_bands"), "JSON response must include gina_bands"
  assert_equal @user.medications.where(medication_type: :reliever).count > 0,
               json["weekly_data"].any?, ...
end
```

## Proposed Solutions

### Option A — Extend existing test with structural assertions (Recommended)
**Effort:** Small | **Risk:** None

```ruby
test "index responds to JSON format" do
  get reliever_usage_url, as: :json
  assert_response :success
  json = response.parsed_body

  # Top-level keys
  assert json.key?("weekly_data")
  assert json.key?("monthly_uses")
  assert json.key?("gina_bands")
  assert json.key?("weeks")

  # weekly_data item shape
  assert json["weekly_data"].any?
  first_week = json["weekly_data"].first
  assert first_week.key?("week_start"), "weekly_data item must have week_start"
  assert first_week.key?("week_end"),   "weekly_data item must have week_end"
  assert first_week.key?("uses"),       "weekly_data item must have uses"
  assert first_week.key?("band"),       "weekly_data item must have band"
  assert first_week.key?("label"),      "weekly_data item must have label"
  assert_includes %w[controlled review urgent], first_week["band"]

  # gina_bands structure
  assert json["gina_bands"].key?("controlled")
  assert json["gina_bands"].key?("review")
  assert json["gina_bands"].key?("urgent")
end
```

## Technical Details

- **Affected files:** `test/controllers/reliever_usage_controller_test.rb`

## Acceptance Criteria

- [ ] JSON test asserts `weekly_data` item shape (all 5 keys present)
- [ ] JSON test asserts `band` values are in `["controlled", "review", "urgent"]`
- [ ] JSON test asserts `gina_bands` has all three tier keys

## Work Log

- 2026-03-10: Identified by kieran-rails-reviewer.
