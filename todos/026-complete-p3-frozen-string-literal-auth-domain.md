---
status: pending
priority: p3
issue_id: "026"
tags: [code-review, quality, ruby, frozen-string-literal]
dependencies: []
---

# `frozen_string_literal: true` Missing on 16 Auth-Domain Files

## Problem Statement

The changeset added `# frozen_string_literal: true` to all infrastructure and base-class files but skipped the authentication domain. All generated controllers, models, mailers, and concerns in the auth layer are missing the comment, creating an inconsistency against the rest of the codebase.

## Findings

**Flagged by:** pattern-recognition-specialist

**Files missing the comment:**
```
app/channels/application_cable/connection.rb
app/controllers/concerns/authentication.rb
app/controllers/passwords_controller.rb
app/controllers/sessions_controller.rb
app/mailers/passwords_mailer.rb
app/models/current.rb
app/models/session.rb
app/models/user.rb
test/controllers/email_verifications_controller_test.rb
test/controllers/passwords_controller_test.rb
test/controllers/registrations_controller_test.rb
test/controllers/sessions_controller_test.rb
test/mailers/previews/passwords_mailer_preview.rb
test/mailers/user_mailer_test.rb
test/models/user_test.rb
test/test_helpers/session_test_helper.rb
```

Also: `app/helpers/application_helper.rb` is missing a blank line between `# frozen_string_literal: true` and the `module` definition (RuboCop omakase requires a blank line before a class/module definition).

## Proposed Solutions

### Solution A: Automated addition via rubocop --autocorrect (Recommended)

```bash
cd ~/Code/asthma-buddy
bin/rubocop --only Style/FrozenStringLiteralComment --autocorrect \
  app/channels/ \
  app/controllers/concerns/authentication.rb \
  app/controllers/passwords_controller.rb \
  app/controllers/sessions_controller.rb \
  app/mailers/passwords_mailer.rb \
  app/models/current.rb \
  app/models/session.rb \
  app/models/user.rb \
  test/controllers/ \
  test/mailers/ \
  test/models/ \
  test/test_helpers/
```
- **Pros:** Automated, consistent, handles blank line requirement too.
- **Effort:** Small (one command + verify)
- **Risk:** None

## Recommended Action

Solution A. Run rubocop autocorrect, verify output, commit.

## Technical Details

- **Affected files:** 16 listed above + `app/helpers/application_helper.rb` blank line
- **RuboCop rule:** `Style/FrozenStringLiteralComment`

## Acceptance Criteria

- [ ] All 16 files have `# frozen_string_literal: true` as first line
- [ ] `app/helpers/application_helper.rb` has blank line between magic comment and `module ApplicationHelper`
- [ ] `bin/rubocop --only Style/FrozenStringLiteralComment` reports no offenses
- [ ] `rails test` passes

## Work Log

- 2026-03-06: Identified by pattern-recognition-specialist during /ce:review of foundation phase changes
