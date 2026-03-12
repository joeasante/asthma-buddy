---
status: pending
priority: p1
issue_id: "288"
tags: [code-review, javascript, stimulus, timezone, bug]
dependencies: []
---

# day_reset_controller.js fires at UTC midnight, not local midnight

## Problem Statement
`day_reset_controller.js` schedules its reload and checks the current date using UTC time (`Date.UTC(...)` and `new Date().toISOString().slice(0,10)`). A user in UTC+10 gets a spurious dashboard reload at 10am their local time instead of midnight. A user in UTC-5 gets it at 7pm. The `checkDate` guard has the same bug — it compares a UTC date string against a server-side `Date.current` value that respects the Rails app timezone, causing false positive reloads across day boundaries for non-UTC users.

## Findings
**Flagged by:** kieran-rails-reviewer, architecture-strategist (both independently identified)

**Location:** `app/javascript/controllers/day_reset_controller.js`

Current broken code:
```js
// scheduleMidnightReload — uses UTC midnight, not local
const nextMidnight = new Date(Date.UTC(
  now.getUTCFullYear(),
  now.getUTCMonth(),
  now.getUTCDate() + 1
))

// checkDate — uses UTC date string, not local
if (new Date().toISOString().slice(0, 10) !== this.dateValue) this.reload()
```

## Proposed Solutions

### Option A — Use local Date constructors throughout (Recommended)
Replace UTC calls with local-time equivalents:
```js
scheduleMidnightReload() {
  const now = new Date()
  const nextMidnight = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1)
  const msUntilMidnight = nextMidnight - now
  this.midnightTimeout = setTimeout(() => this.reload(), msUntilMidnight)
}

checkDate() {
  const now = new Date()
  const today = [
    now.getFullYear(),
    String(now.getMonth() + 1).padStart(2, "0"),
    String(now.getDate()).padStart(2, "0")
  ].join("-")
  if (today !== this.dateValue) this.reload()
}
```
**Pros:** Correct for all timezones. Minimal change. Aligns with how Rails `Date.current` works.
**Cons:** None.
**Effort:** Small. **Risk:** Low.

### Option B — Pass server timezone offset as a data attribute
Render the server's UTC offset on the `data-day-reset` element and use it in JS to compute the correct midnight.
**Pros:** Accounts for server-timezone-aware date values.
**Cons:** Over-engineered. Local time is correct when the user's browser timezone matches their actual location, which is standard. **Effort:** Medium. **Risk:** Low.

## Recommended Action

## Technical Details
- **File:** `app/javascript/controllers/day_reset_controller.js`
- **Methods:** `scheduleMidnightReload()` and `checkDate()`
- **Impact:** All users outside UTC — incorrect reload timing or spurious reloads at wrong time of day

## Acceptance Criteria
- [ ] `scheduleMidnightReload` uses `new Date(year, month, date + 1)` (local time constructor)
- [ ] `checkDate` builds the date string from `getFullYear()`, `getMonth() + 1`, `getDate()` (local time methods)
- [ ] No `Date.UTC()` calls remain in the controller
- [ ] No `.toISOString()` calls used for date comparison

## Work Log
- 2026-03-12: Identified in code review — kieran-rails-reviewer and architecture-strategist both flagged independently

## Resources
- Branch: dev
- File: app/javascript/controllers/day_reset_controller.js
