---
status: pending
priority: p1
issue_id: "108"
tags: [code-review, security, file-upload, active-storage, rails]
dependencies: []
---

# No avatar file type or size validation — arbitrary file upload accepted

## Problem Statement

`User` model has `has_one_attached :avatar` with no content type or size restrictions. Any file can be uploaded as an avatar — executable scripts, SVGs with embedded JS, 500MB videos. This is a security and resource issue.

## Findings

- `app/models/user.rb` — `has_one_attached :avatar`, no `validates :avatar` guard
- `app/controllers/profiles_controller.rb` — `profile_params` permits `:avatar` without server-side type checking
- No Active Storage variant processing validation guards (variant processing malformed images can cause server errors)

## Proposed Solutions

### Option A: Rails validates :avatar (Recommended)
```ruby
# app/models/user.rb
validates :avatar,
  content_type: { in: %w[image/jpeg image/png image/webp image/gif],
                  message: "must be a JPEG, PNG, WebP, or GIF" },
  size: { less_than: 5.megabytes, message: "must be less than 5MB" }
```
**Pros:** Declarative, tested by Rails, errors surface on `user.errors`.
**Cons:** Requires `rails active_storage` content type validation (available since Rails 6.1).
**Effort:** Small | **Risk:** Low

### Option B: Controller-level check
Check `params[:user][:avatar].content_type` in the controller before calling `update`.
**Pros:** Fast feedback.
**Cons:** Bypassed if model is updated directly; not idiomatic Rails.
**Effort:** Small | **Risk:** Low

## Recommended Action

Option A — model-level validation is idiomatic and consistent.

## Technical Details

- **Affected files:** `app/models/user.rb`
- **Security impact:** Unrestricted file upload, potential DoS via large files

## Acceptance Criteria

- [ ] Avatar upload rejects non-image MIME types
- [ ] Avatar upload rejects files larger than 5MB
- [ ] Validation errors display on the profile page
- [ ] Test covering invalid avatar upload in `profiles_controller_test.rb`

## Work Log

- 2026-03-08: Identified by security-sentinel during PR review
