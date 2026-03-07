---
status: pending
priority: p1
issue_id: "048"
tags: [code-review, email, security, configuration]
dependencies: []
---

# ApplicationMailer `from@example.com` Placeholder — Security Emails Won't Deliver

## Problem Statement

`ApplicationMailer` has `default from: "from@example.com"` — a Rails generator placeholder that was never replaced. Both `UserMailer` (email verification) and `PasswordsMailer` (password reset) inherit this. In production, all security-critical emails will fail SPF/DKIM validation, be rejected by receiving mail servers, or land in spam. Users cannot verify accounts or reset passwords.

## Findings

**Flagged by:** kieran-rails-reviewer (CRITICAL), pattern-recognition-specialist (HIGH), security-sentinel (LOW-04), architecture-strategist

**Location:** `app/mailers/application_mailer.rb:4`

```ruby
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"  # generator placeholder — never replaced
  layout "mailer"
end
```

**Neither child mailer overrides `from:`:**
- `app/mailers/user_mailer.rb` — no `from:` override
- `app/mailers/passwords_mailer.rb` — no `from:` override

**Impact:** Email verification and password reset are security-critical flows. If emails fail to deliver:
- Users cannot complete registration
- Password reset is broken
- Users are stranded with locked accounts

Note: A separate todo (010-complete-p2-mailer-host-placeholder.md) addressed `action_mailer.default_url_options` — this is a different issue about the sender address itself.

## Proposed Solutions

### Solution A: Credentials-based from address (Recommended)

```ruby
# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.dig(:mailer, :from_address) ||
                ENV.fetch("MAILER_FROM_ADDRESS", "noreply@asthmabuddy.app")
  layout "mailer"
end
```

Then add to credentials:
```yaml
mailer:
  from_address: "Asthma Buddy <noreply@asthmabuddy.app>"
```

- **Pros:** Keeps sensitive config out of source code, supports per-environment overrides
- **Effort:** Small
- **Risk:** Low

### Solution B: Environment variable only

```ruby
default from: ENV.fetch("MAILER_FROM_ADDRESS")
```
- **Pros:** Simple, explicit — will fail loudly if not set (good)
- **Cons:** Raises `KeyError` at startup if env var missing (could be a problem in dev/test)
- **Effort:** Tiny
- **Risk:** Low

### Solution C: Hardcode for now

```ruby
default from: "Asthma Buddy <noreply@asthmabuddy.app>"
```
- **Pros:** Zero config required, simplest
- **Cons:** Changing the address requires a code deploy
- **Effort:** Minimal
- **Risk:** Low — fine for a single-domain app

## Technical Details

- **Modified file:** `app/mailers/application_mailer.rb`
- **Also check:** SMTP settings in `config/environments/production.rb` are currently commented out — these need to be configured alongside the from address for emails to actually send
- **Related config:** `config.action_mailer.default_url_options = { host: app_host }` is already correct in production.rb

## Acceptance Criteria

- [ ] `ApplicationMailer.default[:from]` is not `"from@example.com"` in any environment
- [ ] The from address is a real, verified sending domain that passes SPF/DKIM
- [ ] Email verification and password reset emails are received in a staging/production test
- [ ] The from address is configurable per environment without code changes

## Work Log

- 2026-03-07: Created from multi-agent code review. Flagged as ship-blocking by kieran-rails-reviewer, pattern-recognition-specialist, security-sentinel.
