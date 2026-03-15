---
status: pending
priority: p3
issue_id: 449
tags: [code-review, billing, ux]
dependencies: []
---

# Pricing Page CTA Only Offers Monthly Plan

## Problem Statement

The pricing page prominently displays both monthly ($7.99) and annual ($59.99) pricing, but the "Start Free Trial" button only sends `plan: "monthly"`. A user who reads about annual savings and clicks the CTA gets monthly. The billing settings page correctly shows both buttons.

## Proposed Solution

Either add a second button ("Start Free Trial (Annual)") or change the label to "Start Free Trial (Monthly)" to set expectations. Match the billing page pattern.

- **Effort**: Small
- **Risk**: None
