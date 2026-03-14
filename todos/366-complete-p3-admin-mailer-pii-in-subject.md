---
status: complete
priority: p3
issue_id: 366
tags: [code-review, security, privacy]
dependencies: []
---

## Problem Statement

`AdminMailer.new_signup` includes the user's email address in the subject line: `"New signup: #{user.email_address}"`. Email subjects are logged by intermediate mail servers, displayed in push notifications, and stored in plaintext in mail server logs, exposing PII in transit metadata.

## Findings

The user's email address is included directly in the email subject, which is not encrypted even when TLS is used for transport. Mail server logs, notification previews on devices, and email client list views all expose the subject line without requiring the email body to be opened.

## Proposed Solutions

- Replace the user email in the subject with a non-PII identifier (e.g., user ID or a generic "New signup notification").
- Move the user email into the email body where it is less broadly exposed.
- Example subject: `"New signup: User ##{user.id}"` or simply `"New user signup"`.

## Technical Details

**Affected files:** app/mailers/admin_mailer.rb

## Acceptance Criteria

- [ ] Admin mailer subject line no longer contains user email or other PII
- [ ] User email is still available in the email body for admin reference
- [ ] Existing mailer tests updated to reflect the new subject format
