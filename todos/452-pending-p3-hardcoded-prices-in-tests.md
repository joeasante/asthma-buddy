---
status: pending
priority: p3
issue_id: 452
tags: [code-review, testing, billing]
dependencies: []
---

# Pricing Controller Test Uses Hardcoded Price Strings

## Problem Statement

`test/controllers/pricing_controller_test.rb` asserts `assert_match "7.99"` and `assert_match "59.99"` instead of referencing `PLANS[:premium][:pricing][:monthly][:display]`. If pricing changes, tests break silently. The `BillingMailerTest` correctly references the PLANS constant.

## Proposed Solution

Replace hardcoded strings with PLANS constant references.

- **Effort**: Trivial
- **Risk**: None
