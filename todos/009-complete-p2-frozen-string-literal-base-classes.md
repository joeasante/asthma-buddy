---
status: pending
priority: p2
issue_id: "009"
tags: [code-review, rails, quality, rubocop]
dependencies: []
---

# `frozen_string_literal` Missing from Base Classes

## Problem Statement

`HomeController` and the WAL initializer have `# frozen_string_literal: true`, but the Rails-generated base files do not. `rubocop-rails-omakase` enforces this magic comment on all files. Without it on `ApplicationController`, `ApplicationRecord`, and `ApplicationJob`, `bin/rubocop` will fail in CI for every future file that inherits from them — or every developer will need to remember to add it manually.

## Findings

**Flagged by:** architecture-strategist, pattern-recognition-specialist

**Files missing the comment:**
- `app/controllers/application_controller.rb`
- `app/models/application_record.rb`
- `app/jobs/application_job.rb`
- `app/mailers/application_mailer.rb`
- `config/application.rb`
- Various other generator-created files

## Proposed Solutions

### Option A — Run `bin/rubocop -a` (Recommended)
Auto-correct adds the magic comment to all files that need it.

```bash
cd ~/Code/asthma-buddy && bin/rubocop -a --only Style/FrozenStringLiteralComment
```

**Effort:** Trivial
**Risk:** None

### Option B — Add manually to each file
Add `# frozen_string_literal: true` to each file by hand.

**Effort:** Small
**Risk:** None (but slower than option A)

## Recommended Action

Option A — run rubocop auto-correct.

## Technical Details

**Acceptance Criteria:**
- [ ] `bin/rubocop` passes with no `Style/FrozenStringLiteralComment` violations
- [ ] All application base classes have the magic comment

## Work Log

- 2026-03-06: Identified by architecture-strategist and pattern-recognition-specialist.
