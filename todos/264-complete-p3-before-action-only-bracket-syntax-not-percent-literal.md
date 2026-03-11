---
status: pending
priority: p3
issue_id: "264"
tags: [code-review, rails, style]
dependencies: []
---

# `before_action only:` Uses Bracket Syntax Instead of Project `%i[]` Convention

## Problem Statement

`NotificationsController` line 5 uses `only: [:mark_read]` — the bracket array literal. Every other controller in the project uses the percent-literal syntax `only: %i[mark_read]` for `before_action` `only:` and `except:` arrays. This is a small but easy-to-fix inconsistency with the project style.

## Findings

`app/controllers/notifications_controller.rb` line 5:

```ruby
before_action :set_notification, only: [:mark_read]
```

Existing controllers using `%i[]` consistently:

```ruby
# app/controllers/settings/medications_controller.rb
before_action :set_medication, only: %i[edit update destroy]

# app/controllers/dose_logs_controller.rb
before_action :set_dose_log, only: %i[destroy]

# app/controllers/health_events_controller.rb
before_action :set_health_event, only: %i[show edit update destroy]
```

Confirmed by: kieran-rails-reviewer.

## Proposed Solutions

### Option A — Change to `%i[]` syntax *(Recommended)*

```ruby
before_action :set_notification, only: %i[mark_read]
```

Pros: consistent with the rest of the codebase; RuboCop omakase enforces this style
Cons: none

## Recommended Action

Option A — change `only: [:mark_read]` to `only: %i[mark_read]`.

## Technical Details

- **Affected file:** `app/controllers/notifications_controller.rb` line 5

## Acceptance Criteria

- [ ] `before_action :set_notification` uses `only: %i[mark_read]`
- [ ] No bracket array literals remain in `before_action` `only:`/`except:` clauses in this file
- [ ] RuboCop passes with no new offenses

## Work Log

- 2026-03-11: Found by kieran-rails-reviewer during Phase 19 code review
