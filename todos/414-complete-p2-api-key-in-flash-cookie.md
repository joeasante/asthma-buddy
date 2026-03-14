---
status: complete
priority: p2
issue_id: "414"
tags: [code-review, security, api, session]
dependencies: []
---

# Plaintext API Key Stored in Flash (Passes Through Cookie)

## Problem Statement

After generating an API key, the plaintext is stored in `flash[:api_key]` and shown after a redirect. Flash is stored in the session cookie, meaning the plaintext key travels through the cookie jar. While Rails encrypts the cookie, this expands the surface area for the key unnecessarily.

## Findings

**Flagged by:** kieran-rails-reviewer, security-sentinel

**Location:** `app/controllers/settings/api_keys_controller.rb`, line 13

```ruby
flash[:api_key] = plaintext_key
redirect_to settings_api_key_path, notice: "..."
```

## Proposed Solutions

### Option A: Render inline without redirect (Recommended)

```ruby
def create
  @plaintext_key = Current.user.generate_api_key!
  @has_key = true
  @key_created_at = Current.user.api_key_created_at
  flash.now[:notice] = "API key generated. Copy it now — it won't be shown again."
  render :show
end
```

- **Pros:** Key never enters cookie, simpler flow
- **Cons:** POST renders instead of redirects (breaks PRG pattern)
- **Effort:** Small (10 min)
- **Risk:** Low

## Acceptance Criteria

- [ ] Plaintext key never stored in flash/cookie
- [ ] Key still displayed once after generation
- [ ] All tests pass

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 28 code review | 2 agents flagged |
