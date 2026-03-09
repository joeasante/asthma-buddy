---
status: pending
priority: p2
issue_id: "117"
tags: [code-review, rails, quality, migration, ruby]
dependencies: []
---

# Both new migrations missing `# frozen_string_literal: true` comment

## Problem Statement

Every existing migration in this codebase starts with `# frozen_string_literal: true`. Both new migrations from this PR are missing it, breaking the codebase-wide convention.

## Findings

- `db/migrate/20260308095600_add_profile_fields_to_users.rb` — no `frozen_string_literal` comment
- `db/migrate/20260308095602_add_triggers_to_symptom_logs.rb` — no `frozen_string_literal` comment
- All pre-existing migrations have the comment (verified by pattern-recognition-specialist)

## Proposed Solutions

### Option A: Add the magic comment to both files
```ruby
# frozen_string_literal: true

class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
```

**Effort:** Small | **Risk:** Low

## Recommended Action

Option A.

## Technical Details

- **Affected files:** `db/migrate/20260308095600_add_profile_fields_to_users.rb`, `db/migrate/20260308095602_add_triggers_to_symptom_logs.rb`

## Acceptance Criteria

- [ ] Both migration files start with `# frozen_string_literal: true`
- [ ] `bin/rubocop db/migrate/` passes with no offense on these files

## Work Log

- 2026-03-08: Identified by pattern-recognition-specialist during PR review
