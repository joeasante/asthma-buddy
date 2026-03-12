---
status: complete
priority: p3
issue_id: "336"
tags: [code-review, javascript, simplification, stimulus]
dependencies: []
---

# `day_reset_controller.js` Verbose Date Construction

## Problem Statement

`app/javascript/controllers/day_reset_controller.js:27-35` constructs today's date string using verbose multi-step JavaScript (year, month, day extracted separately, zero-padded manually). The same result can be achieved in one line with `new Date().toISOString().slice(0, 10)`, which is well-supported in all modern browsers and eliminates ~8 lines of boilerplate.

## Findings

**Flagged by:** code-simplicity-reviewer

Current (verbose):
```javascript
const now = new Date()
const year = now.getFullYear()
const month = String(now.getMonth() + 1).padStart(2, '0')
const day = String(now.getDate()).padStart(2, '0')
const today = `${year}-${month}-${day}`
```

Simplified:
```javascript
const today = new Date().toISOString().slice(0, 10)
```

Note: `toISOString()` returns UTC date. If the app displays dates in the user's local timezone and this matters for the reset logic, use `new Intl.DateTimeFormat('en-CA').format(new Date())` which returns `YYYY-MM-DD` in local time.

## Proposed Solutions

### Option A: Use `toISOString().slice(0, 10)` (Recommended if UTC is fine)
```javascript
const today = new Date().toISOString().slice(0, 10)
```

**Pros:** 1 line vs 5; universally understood
**Cons:** Returns UTC date — may differ from local date near midnight
**Effort:** Tiny
**Risk:** Low (check if UTC vs local matters for the reset trigger)

### Option B: Use `Intl.DateTimeFormat` for local date
```javascript
const today = new Intl.DateTimeFormat('en-CA').format(new Date())
```

**Pros:** Returns local date (YYYY-MM-DD format)
**Cons:** Slightly less obvious
**Effort:** Tiny
**Risk:** None

### Recommended Action

Option B if the day reset logic is timezone-sensitive (likely, given the London timezone context). Option A otherwise.

## Technical Details

- **File:** `app/javascript/controllers/day_reset_controller.js:27-35`

## Acceptance Criteria

- [ ] Date construction reduced to 1 line
- [ ] Day reset still triggers correctly for London timezone users
- [ ] No JS test regressions

## Work Log

- 2026-03-12: Created from Milestone 2 code review — code-simplicity-reviewer finding
