---
status: pending
priority: p2
issue_id: "139"
tags: [code-review, api, agent-native, profiles, avatar]
dependencies: ["129"]
---

# `profile_json` Omits `avatar_url` — Agents Cannot Confirm Avatar Upload

## Problem Statement

Agents can upload a profile avatar via `PATCH /profile`, but the JSON response body never includes a URL pointing to the uploaded image. An agent that uploads an avatar receives a response with no `avatar_url` and cannot confirm the upload succeeded, generate a link for display, or report back to the user.

Flagged by: agent-native-reviewer.

## Findings

**File:** `app/controllers/profiles_controller.rb`, `profile_json` private method

```ruby
def profile_json
  {
    id:            Current.user.id,
    full_name:     Current.user.full_name,
    date_of_birth: Current.user.date_of_birth
  }
end
```

`Current.user.avatar` is an Active Storage attachment. `url_for(Current.user.avatar)` generates the URL. This only requires calling `url_for` which is available in controllers.

## Proposed Solution

```ruby
def profile_json
  {
    id:            Current.user.id,
    full_name:     Current.user.full_name,
    date_of_birth: Current.user.date_of_birth,
    avatar_url:    Current.user.avatar.attached? ? url_for(Current.user.avatar) : nil
  }
end
```

## Acceptance Criteria

- [ ] `GET /profile` JSON includes `avatar_url` (non-nil when avatar is attached, `null` when not)
- [ ] `PATCH /profile` JSON response includes `avatar_url`
- [ ] `profiles_controller_test.rb` has a test asserting `avatar_url` key in JSON response
- [ ] `avatar_url` is a valid, absolute URL when avatar is attached

## Work Log

- 2026-03-08: Identified by agent-native-reviewer
