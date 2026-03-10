---
status: pending
priority: p2
issue_id: "178"
tags: [code-review, security, action-text, lexxy]
dependencies: []
---

# ActionText Allows embed Tag in Rich Text Content

## Problem Statement
Lexxy adds `embed` to ActionText::ContentHelper.allowed_tags. The `<embed>` element can load arbitrary external resources including PDFs, Flash objects, and plugins. Even without Flash, a crafted `<embed src="https://attacker.com/payload">` in a note could cause SSRF from the browser or content injection. Health notes are medical records and should not accept external resource embeds.

## Proposed Solutions

### Option A
Add to the same initializer as #177:

```ruby
ActionText::ContentHelper.allowed_tags -= %w[embed]
```
- Effort: Small
- Risk: Low

## Recommended Action

## Technical Details
- Affected files: config/initializers/action_text_sanitization.rb (combine with #177 fix)

## Acceptance Criteria
- [ ] `embed` is removed from ActionText::ContentHelper.allowed_tags in the sanitization initializer
- [ ] Fix is combined with the #177 initializer in config/initializers/action_text_sanitization.rb
- [ ] `<embed>` tags in rich text note content are stripped on render
- [ ] No Lexxy editor features rely on the embed tag (verify by testing all editor toolbar actions)

## Work Log
- 2026-03-10: Created via code review
