---
status: pending
priority: p3
issue_id: "060"
tags: [code-review, developer-experience, email, testing]
dependencies: []
---

# Missing `UserMailerPreview` — Email Verification Email Not Inspectable in Development

## Problem Statement

`test/mailers/previews/passwords_mailer_preview.rb` exists, but there is no preview for `UserMailer`. Developers cannot inspect the email verification email at `http://localhost:3000/rails/mailers/user_mailer` in development, making it harder to iterate on the email template.

## Findings

**Flagged by:** pattern-recognition-specialist

**Existing preview:** `test/mailers/previews/passwords_mailer_preview.rb`

```ruby
class PasswordsMailerPreview < ActionMailer::Preview
  def reset
    PasswordsMailer.reset(User.take)  # Note: User.take returns nil on empty DB — also a bug
  end
end
```

**Missing:** `test/mailers/previews/user_mailer_preview.rb`

**Secondary bug:** `PasswordsMailerPreview` uses `User.take` which returns nil on an empty DB, raising `NoMethodError` when accessing the preview. Should use `User.first!`.

## Proposed Solution

Create `test/mailers/previews/user_mailer_preview.rb`:

```ruby
class UserMailerPreview < ActionMailer::Preview
  def email_verification
    UserMailer.email_verification(User.first!)
  end
end
```

Also fix `PasswordsMailerPreview`:

```ruby
class PasswordsMailerPreview < ActionMailer::Preview
  def reset
    PasswordsMailer.reset(User.first!)  # User.first! raises descriptive error if DB is empty
  end
end
```

- **Effort:** Tiny
- **Risk:** None

## Acceptance Criteria

- [ ] `http://localhost:3000/rails/mailers/user_mailer/email_verification` renders the verification email
- [ ] `PasswordsMailerPreview` uses `User.first!` instead of `User.take`

## Work Log

- 2026-03-07: Created from pattern review. pattern-recognition-specialist.
