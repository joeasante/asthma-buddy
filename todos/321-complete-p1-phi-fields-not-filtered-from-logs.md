---
status: complete
priority: p1
issue_id: "321"
tags: [code-review, security, privacy, phi, logging, gdpr]
dependencies: []
---

# PHI Fields Not Filtered from Rails Logs

## Problem Statement

`config/initializers/filter_parameter_logging.rb` does not include `user[full_name]`, `user[date_of_birth]`, or `user[avatar]` in the filtered parameters list. When users update their profile (name, date of birth, avatar upload), these PHI (Protected Health Information) fields appear in plaintext in Rails production logs. Under UK GDPR, logging personal health-adjacent data (date of birth, full name tied to a health tracking account) without appropriate controls constitutes a data protection risk. The privacy policy explicitly states all PHI is protected — logs leaking it violates that promise.

## Findings

**Flagged by:** security-sentinel (rated P1 — PHI exposure)

Current filter list likely only covers `password` and similar auth fields. Profile update params include:
- `user[full_name]` — personally identifiable
- `user[date_of_birth]` — sensitive personal data
- `user[avatar]` — binary upload (also noisy in logs)

Additionally, health data params (symptom notes, peak flow values) should be audited for log filtering — prior todo 085 addressed `symptom_log` but the profile fields were missed.

## Proposed Solutions

### Option A: Add fields to filter_parameter_logging.rb (Recommended)
Extend `Rails.application.config.filter_parameters` to include profile fields.

```ruby
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  :full_name, :date_of_birth, :avatar,
  "user[full_name]", "user[date_of_birth]", "user[avatar]"
]
```

Rails filter_parameters supports both symbol and string matchers; using both ensures nested and flat params are covered.

**Pros:** Simple, complete, follows Rails convention
**Cons:** None
**Effort:** Small
**Risk:** None

### Option B: Use regex pattern
Add a regex that catches all `user[*]` params:

```ruby
Rails.application.config.filter_parameters += [/user\[.+\]/]
```

**Pros:** Catches any future user fields automatically
**Cons:** May over-filter useful debug fields (e.g. `user[email]` is sometimes needed for debugging)
**Effort:** Small
**Risk:** Low

### Recommended Action

Option A — explicit fields are clearer and more intentional.

## Technical Details

- **File:** `config/initializers/filter_parameter_logging.rb`
- Profile controller: `app/controllers/profiles_controller.rb` (submits `user[full_name]`, `user[date_of_birth]`, `user[avatar]`)

## Acceptance Criteria

- [ ] `full_name`, `date_of_birth`, and `avatar` are in the filtered parameters list
- [ ] Rails logs show `[FILTERED]` for these fields on profile update requests
- [ ] Existing tests pass

## Work Log

- 2026-03-12: Created from Milestone 2 code review — security-sentinel P1 finding
