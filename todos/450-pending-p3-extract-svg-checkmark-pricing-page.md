---
status: pending
priority: p3
issue_id: 450
tags: [code-review, code-quality, views]
dependencies: []
---

# Extract Duplicated SVG Checkmark in Pricing Page

## Problem Statement

The same SVG checkmark markup (5 lines) is duplicated 11 times in `app/views/pricing/show.html.erb` (~55 lines). Extract to a helper method or partial.

## Proposed Solution

Create `app/helpers/pricing_helper.rb` with `pricing_check_icon` method, or extract to `app/views/shared/_check_icon.html.erb` partial.

- **Effort**: Small
- **Risk**: None
