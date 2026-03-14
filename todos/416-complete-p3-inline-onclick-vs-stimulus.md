---
status: complete
priority: p3
issue_id: "416"
tags: [code-review, frontend, conventions, api]
dependencies: []
---

# Inline onclick Handler on API Key Copy Button

## Problem Statement

The API key copy button uses a 178-character inline `onclick` JavaScript handler, which is inconsistent with the Stimulus convention used elsewhere in the app.

## Findings

**Flagged by:** code-simplicity-reviewer

**Location:** `app/views/settings/api_keys/show.html.erb`, line 40

## Proposed Solutions

### Option A: Use a Stimulus clipboard controller

If a clipboard Stimulus controller already exists, wire it up. If not, the inline handler is acceptable for a single button.

- **Effort:** Small (10 min)
- **Risk:** None

## Acceptance Criteria

- [ ] Copy button works correctly
- [ ] Follows Stimulus convention if controller exists

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 28 code review | Minor consistency note |
