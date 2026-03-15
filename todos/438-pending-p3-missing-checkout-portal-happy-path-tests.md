---
status: pending
priority: p3
issue_id: 438
tags: [code-review, testing, billing]
dependencies: []
---

# Missing Happy-Path Tests for Checkout and Portal Actions

## Problem Statement

Billing controller tests verify policy denial but not that a free user CAN initiate checkout or a premium user CAN access portal. Every other settings controller tests its happy paths.

## Findings

- **Source:** Pattern Recognition, Rails Reviewer
- **Location:** `test/controllers/settings/billing_controller_test.rb`

## Proposed Solutions

Add tests that stub Stripe calls and verify the controller redirects to the Stripe URL.

- **Effort:** Medium (requires mocking Pay/Stripe)
- **Risk:** Low

## Acceptance Criteria

- [ ] Test: free user POST checkout → redirects (with stubbed Stripe)
- [ ] Test: premium user POST portal → redirects (with stubbed Stripe)

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-15 | Created from Phase 29 code review | |
