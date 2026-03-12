---
status: complete
priority: p3
issue_id: "333"
tags: [code-review, frontend, turbo, consistency]
dependencies: []
---

# Toast Variant Inconsistency: `notice` vs `success` in Medication/Dose Turbo Streams

## Problem Statement

Turbo stream responses across the app use `data-toast-variant="success"` for positive confirmation toasts. However, `settings/medications/destroy.turbo_stream.erb` and `settings/dose_logs/destroy.turbo_stream.erb` use `data-toast-variant="notice"`. This inconsistency means delete confirmations for medications render with a different visual style than all other success states.

Additionally, `refill.turbo_stream.erb` uses `render "layouts/flash"` (a full partial) instead of the inline toast HTML pattern used everywhere else, creating a different code path for refill confirmations.

## Findings

**Flagged by:** pattern-recognition-specialist

- `settings/medications/destroy.turbo_stream.erb`: `data-toast-variant="notice"` (should be `"success"`)
- `settings/dose_logs/destroy.turbo_stream.erb`: `data-toast-variant="notice"` (should be `"success"`)
- `refill.turbo_stream.erb`: uses `layouts/flash` partial instead of inline toast HTML

## Proposed Solutions

### Option A: Standardise to `success` (Recommended)
Change `notice` → `success` in both destroy turbo stream views. Update `refill.turbo_stream.erb` to use inline toast HTML matching the other turbo streams.

**Pros:** Visual consistency across all confirmation toasts
**Cons:** None — `notice` style doesn't convey deletion semantics anyway
**Effort:** Tiny
**Risk:** None

### Recommended Action

Option A.

## Technical Details

- `app/views/settings/medications/destroy.turbo_stream.erb`
- `app/views/settings/dose_logs/destroy.turbo_stream.erb`
- `app/views/settings/medications/refill.turbo_stream.erb`

## Acceptance Criteria

- [ ] All destroy and refill turbo streams use `data-toast-variant="success"`
- [ ] `refill.turbo_stream.erb` uses inline toast HTML, not the flash partial
- [ ] Visual spot-check: delete medication and dose log toasts match other success toasts

## Work Log

- 2026-03-12: Created from Milestone 2 code review — pattern-recognition-specialist finding
