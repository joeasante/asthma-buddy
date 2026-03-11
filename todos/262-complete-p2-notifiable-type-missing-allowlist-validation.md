---
status: pending
priority: p2
issue_id: "262"
tags: [code-review, security, rails]
dependencies: []
---

# `notifiable_type` Accepts Arbitrary Strings Without Allowlist Validation

## Problem Statement

The `notifiable_type` column is an unconstrained VARCHAR. No model-level validation constrains `notifiable_type` to safe values (`Medication` only, for now). The fixture `alice_read_old` sets `notifiable_type: User` — accessing `notification.notifiable` on a `User` record would return a `User` object including `password_digest` and all attributes. If future code paths allow user influence over `notifiable_type`, this becomes an object traversal vulnerability.

## Findings

`app/models/notification.rb` — no `NOTIFIABLE_TYPES` constant and no `validates :notifiable_type` present.

`db/migrate/20260311093356_create_notifications.rb` — `notifiable_type` is created as an unconstrained string column with no database-level check constraint.

Test fixtures — `alice_read_old` sets `notifiable_type: User`, demonstrating the model accepts arbitrary class names.

- `belongs_to :notifiable, polymorphic: true, optional: true` resolves `notifiable_type` via `Object.const_get(notifiable_type)` internally, meaning any valid Ruby constant name would be looked up.
- A `User` notifiable exposes the full `User` record — including `password_digest` — to any code path that calls `notification.notifiable`.
- No allowlist exists at the model, controller, or DB level to reject unexpected values.

Confirmed by: kieran-rails-reviewer.

## Proposed Solutions

### Option A — Add a constant allowlist and model validation *(Recommended)*

```ruby
# app/models/notification.rb
NOTIFIABLE_TYPES = %w[Medication].freeze

validates :notifiable_type, inclusion: { in: NOTIFIABLE_TYPES }, allow_nil: true
```

Pros: any attempt to set an unexpected `notifiable_type` raises a validation error; easy to extend when new notifiable types are added intentionally; self-documenting via the constant
Cons: none

### Option B — Add a DB-level check constraint (complementary)

```ruby
# New migration
add_check_constraint :notifications,
  "notifiable_type IN ('Medication')",
  name: "notifications_notifiable_type_allowlist"
```

Pros: enforced at the database layer regardless of whether Rails validations are bypassed
Cons: requires a migration; needs updating whenever `NOTIFIABLE_TYPES` grows; best used alongside Option A, not instead of it.

## Recommended Action

Option A immediately (model validation). Option B as a follow-on migration for defence in depth. Fix the `alice_read_old` fixture to remove `notifiable_type: User`.

## Technical Details

- **Affected files:**
  - `app/models/notification.rb`
  - `db/migrate/20260311093356_create_notifications.rb`
  - `test/fixtures/notifications.yml` (remove `notifiable_type: User` from `alice_read_old`)

## Acceptance Criteria

- [ ] `Notification::NOTIFIABLE_TYPES = %w[Medication].freeze` is defined on the model
- [ ] `validates :notifiable_type, inclusion: { in: NOTIFIABLE_TYPES }, allow_nil: true` is present on the model
- [ ] `Notification.new(notifiable_type: "User").valid?` returns `false`
- [ ] `Notification.new(notifiable_type: "Medication").valid?` does not fail on the type validation
- [ ] The `alice_read_old` fixture no longer uses `notifiable_type: User`
- [ ] All existing notification model and fixture-dependent tests continue to pass

## Work Log

- 2026-03-11: Found by kieran-rails-reviewer during Phase 19 code review
