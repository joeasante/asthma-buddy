---
status: pending
priority: p1
issue_id: "257"
tags: [code-review, rails, agent-native]
dependencies: []
---

# NotificationsController Missing format.json on All Actions

## Problem Statement

All three actions in `NotificationsController` (`index`, `mark_read`, `mark_all_read`) respond only to `turbo_stream` and `html`. No `format.json` branch exists on any action. This is a regression from the pattern established in the two most recent PRs: `dose_logs_controller` and `medications_controller` both added `format.json` as a required part of their implementation.

An agent sending `Accept: application/json` to any notifications endpoint receives either a 406 Not Acceptable response (`mark_read`, `mark_all_read`) or an HTML document body (`index`). The notification feed and read-state mutations are therefore not programmatically accessible. The `index` action additionally needs to return `unread_count` in its JSON body so that agents can render badge state without a separate request.

## Findings

`app/controllers/notifications_controller.rb`:

```ruby
def index
  respond_to do |format|
    format.html
    format.turbo_stream
    # format.json missing
  end
end

def mark_read
  # ...
  respond_to do |format|
    format.html  { redirect_to ... }
    format.turbo_stream { ... }
    # format.json missing — returns 406
  end
end

def mark_all_read
  # ...
  respond_to do |format|
    format.html  { redirect_to ... }
    format.turbo_stream { ... }
    # format.json missing — returns 406
  end
end
```

Pattern established by prior art:
- `app/controllers/dose_logs_controller.rb` — `format.json` on all mutating actions
- `app/controllers/settings/medications_controller.rb` — `format.json` on index and mutating actions

## Proposed Solutions

### Option A — Add format.json to all three actions *(Recommended)*

```ruby
def index
  respond_to do |format|
    format.html
    format.turbo_stream
    format.json do
      render json: {
        notifications: @notifications.as_json(only: %i[id notification_type read created_at]),
        unread_count: current_user.notifications.unread.count
      }
    end
  end
end

def mark_read
  # ... existing logic ...
  respond_to do |format|
    format.html  { redirect_to root_path }
    format.turbo_stream { ... }
    format.json  { render json: @notification.as_json(only: %i[id read]) }
  end
end

def mark_all_read
  # ... existing logic ...
  respond_to do |format|
    format.html  { redirect_to root_path }
    format.turbo_stream { ... }
    format.json  { render json: { unread_count: 0 } }
  end
end
```

Pros: consistent with codebase convention; makes notification state accessible to agents
Cons: minor — small surface area increase

## Recommended Action

Option A — add `format.json` to all three actions and add controller tests covering each JSON path.

## Technical Details

- **Affected file:** `app/controllers/notifications_controller.rb`

## Acceptance Criteria

- [ ] `index` responds to `Accept: application/json` with a JSON body containing `notifications` array and `unread_count`
- [ ] `mark_read` responds to `Accept: application/json` with the updated notification or `head :ok`
- [ ] `mark_all_read` responds to `Accept: application/json` with `{ unread_count: 0 }` or `head :ok`
- [ ] No action returns 406 for a JSON request
- [ ] Controller tests added for all three JSON paths
- [ ] Existing turbo_stream and html tests continue to pass

## Work Log

- 2026-03-11: Found by kieran-rails-reviewer during Phase 19 code review
