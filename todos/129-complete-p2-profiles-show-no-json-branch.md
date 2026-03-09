---
status: pending
priority: p2
issue_id: "129"
tags: [code-review, api, agent-native, profiles]
dependencies: []
---

# `profiles#show` Has No JSON Branch

## Problem Statement

`ProfilesController#show` has no `respond_to` block. A JSON `GET /profile` receives an HTML response (or 406 Not Acceptable). Agents cannot read the user's profile. The `profile_json` private method is already written and used by `update` — this is a one-line fix.

Flagged by: agent-native-reviewer.

## Findings

**File:** `app/controllers/profiles_controller.rb`, `show` action

```ruby
def show
end
```

No `respond_to` block. `profile_json` exists at the bottom of the controller but is never called from `show`.

## Proposed Solution

```ruby
def show
  respond_to do |format|
    format.html
    format.json { render json: profile_json }
  end
end
```

Also add `avatar_url` to `profile_json` (see todo #139).

## Acceptance Criteria

- [ ] `GET /profile` with `Accept: application/json` returns 200 with JSON body
- [ ] JSON includes `id`, `full_name`, `date_of_birth`
- [ ] `profiles_controller_test.rb` has a test for JSON show
- [ ] Unauthenticated JSON request returns 401

## Work Log

- 2026-03-08: Identified by agent-native-reviewer
