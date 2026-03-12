---
status: complete
priority: p2
issue_id: "329"
tags: [code-review, agent-native, json, settings]
dependencies: []
---

# `SettingsController#show` and `ProfilesController#remove_avatar` Missing JSON Responses

## Problem Statement

`SettingsController#show` and `ProfilesController#remove_avatar` have no JSON response branches. Agents navigating the settings hub or modifying user profiles cannot confirm actions or retrieve settings state programmatically.

## Findings

**Flagged by:** agent-native-reviewer

- `SettingsController#show`: returns only HTML; no JSON branch
- `ProfilesController#remove_avatar`: `delete` action has no `format.json` path; agents receive HTML redirect on success
- `ProfilesController#update`: check whether JSON is covered (may already be present from prior todos)

## Proposed Solutions

### Option A: Add `respond_to` blocks
For `SettingsController#show`, return a summary of available settings sections and key user config:
```ruby
format.json do
  render json: {
    profile: { full_name: Current.user.full_name, email: Current.user.email_address },
    medications_count: @medications_count,
    notifications_enabled: Current.user.notifications_enabled
  }
end
```

For `ProfilesController#remove_avatar`:
```ruby
format.json { render json: { success: true } }
```

**Pros:** Consistent with project agent-native pattern; minimal effort
**Cons:** Requires deciding canonical JSON shape for settings
**Effort:** Small
**Risk:** Low

### Recommended Action

Option A for both.

## Technical Details

- **Files:** `app/controllers/settings_controller.rb`, `app/controllers/profiles_controller.rb`

## Acceptance Criteria

- [ ] `GET /settings.json` returns user settings summary
- [ ] `DELETE /profile/avatar.json` returns `{ success: true }` on success
- [ ] Controller tests cover JSON format for both

## Work Log

- 2026-03-12: Created from Milestone 2 code review — agent-native-reviewer finding
