---
status: pending
priority: p1
issue_id: "256"
tags: [code-review, rails, bug]
dependencies: []
---

# resolve_notification_path rescue is dead code

## Problem Statement

`resolve_notification_path` in `NotificationsController` wraps its logic in a `begin/rescue ActiveRecord::RecordNotFound` block that can never fire. Because `belongs_to :notifiable, optional: true` is declared on the `Notification` model, accessing a polymorphic `notifiable` whose referenced record has been deleted returns `nil` — it does not raise `RecordNotFound`. The rescue block is therefore unreachable dead code.

Compounding the issue, both rescue branches (`low_stock` and `missed_dose`) return the same path they would return in the non-rescue path, making the entire rescue construct doubly redundant. The method also double-marks-read: the rescue branch calls `update_columns(read: true)` but `mark_read` already calls `update!(read: true)` unconditionally on line 16, so that call inside the rescue is also dead.

## Findings

`app/controllers/notifications_controller.rb` lines 45–66:

```ruby
def resolve_notification_path(notification)
  begin
    case notification.notification_type
    when "low_stock"
      settings_medications_path
    when "missed_dose"
      root_path
    else
      root_path
    end
  rescue ActiveRecord::RecordNotFound
    notification.update_columns(read: true)
    case notification.notification_type
    when "low_stock"   then settings_medications_path
    when "missed_dose" then root_path
    else root_path
    end
  end
end
```

- `belongs_to :notifiable, optional: true` means a missing associated record returns `nil` — not an exception.
- The rescue paths return the exact same values as the non-rescue paths.
- `update_columns(read: true)` inside rescue is unreachable; `mark_read` (line 16) already persists `read: true` unconditionally before this method is called.

Confirmed by: kieran-rails-reviewer.

## Proposed Solutions

### Option A — Remove the rescue block and simplify to a plain case/when *(Recommended)*

```ruby
def resolve_notification_path(notification)
  case notification.notification_type
  when "low_stock"   then settings_medications_path
  when "missed_dose" then root_path
  else root_path
  end
end
```

Pros: removes all dead code, clearer intent, no hidden control-flow surprise
Cons: none — behaviour is identical

### Option B — Guard on notifiable presence separately if needed

If future notification types need to navigate to the notifiable record's show page, introduce an explicit nil-guard at the point where `notification.notifiable` is accessed, not via rescue.

Pros: extensible pattern
Cons: not needed yet; premature

## Recommended Action

Option A — delete the begin/rescue entirely. The method is a simple routing lookup; no exception handling is warranted.

## Technical Details

- **Affected file:** `app/controllers/notifications_controller.rb` lines 45–66

## Acceptance Criteria

- [ ] `resolve_notification_path` contains no `begin/rescue` block
- [ ] All three `notification_type` cases (`low_stock`, `missed_dose`, else) still route to the correct path
- [ ] Existing controller tests for the `mark_read` action continue to pass
- [ ] No `update_columns` call inside `resolve_notification_path`

## Work Log

- 2026-03-11: Found by kieran-rails-reviewer during Phase 19 code review
