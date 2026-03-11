---
status: pending
priority: p2
issue_id: "269"
tags:
  - code-review
  - rails
  - bug
  - notifications
dependencies: []
---

# read: false in deduplication exists? predicate re-creates notification after user dismisses it

## Problem Statement

The deduplication `exists?` predicate in `Notification.create_low_stock_for` and `MissedDoseCheckJob` includes `read: false` as a condition. This means the deduplication check only skips creation if an **unread** notification already exists. Once a user reads (dismisses) a low-stock notification and then logs another dose — which is the normal workflow after seeing the alert — the `exists?` check returns `false` (the existing notification is now read), and a brand-new low-stock notification is created. The user sees a fresh alert for the same medication they already acknowledged.

This defeats the purpose of deduplication: one alert per event, not one alert per dose after the first acknowledgement.

## Findings

**File:** `app/models/notification.rb`, line 24
```ruby
return if exists?(user: user, notification_type: :low_stock, notifiable: medication, read: false)
```

**File:** `app/jobs/missed_dose_check_job.rb`, lines 26-33
```ruby
next if Notification.exists?(
  user:              medication.user,
  notification_type: :missed_dose,
  notifiable:        medication,
  read:              false,
  created_at:        today.beginning_of_day..today.end_of_day
)
```

**Scenario that triggers the bug (low_stock):**
1. User has 10 doses remaining (below 14-day threshold)
2. User logs a dose → `after_create_commit` fires → `create_low_stock_for` called
3. `exists?(... read: false)` → no unread notification found → creates notification A
4. User opens /notifications, reads notification A → `read: true` on A
5. User logs another dose → `after_create_commit` fires → `create_low_stock_for` called
6. `exists?(... read: false)` → returns false (only read notification exists) → creates notification B (duplicate)

**Scenario that triggers the bug (missed_dose):**
The daily job deduplicates within the same day's window using `created_at:` range, but also filters `read: false`. If a user reads the missed-dose notification and the job re-runs (e.g. job retry, manual re-queue), a second notification is created for the same medication/day.

## Proposed Solutions

### Option A: Remove `read: false` from the exists? predicate (Recommended)
- **Approach:** Drop `read: false` from both deduplication `exists?` calls. The check becomes: "does any notification (read or unread) exist for this medication at this type?" — which is the correct deduplication semantic.
- **Pros:** One-line fix per site. Correct semantics. No schema change.
- **Cons:** A user who reads a low-stock notification will not receive another one on subsequent doses — this is the intended behaviour.
- **Effort:** Small
- **Risk:** Low

```ruby
# notification.rb — remove read: false
return if exists?(user: user, notification_type: :low_stock, notifiable: medication)

# missed_dose_check_job.rb — remove read: false from the predicate
next if Notification.exists?(
  user:              medication.user,
  notification_type: :missed_dose,
  notifiable:        medication,
  created_at:        today.beginning_of_day..today.end_of_day
)
```

### Option B: Use a time-window instead of read-state for low_stock deduplication
- **Approach:** Instead of deduplicating on `read: false`, deduplicate on `created_at` within a 24-hour or 7-day window. After the window expires, a new notification is permitted (the user may have refilled and run low again).
- **Pros:** Allows a legitimate "re-alert" after a reasonable quiet period.
- **Cons:** More complex. Requires defining the window. Overkill for current scale.
- **Effort:** Medium
- **Risk:** Low

### Option C: Add a `dismissed` boolean separate from `read`
- **Approach:** Add a `dismissed` boolean to Notification. Deduplication checks `dismissed: false`. Reading a notification marks it `read: true` but not `dismissed`. User can explicitly dismiss to stop future alerts.
- **Pros:** Separates "seen" from "acknowledged as resolved".
- **Cons:** Schema change. Significantly more complex. Over-engineering for current scope.
- **Effort:** Large
- **Risk:** Medium

## Recommended Action

Option A — remove `read: false` from both `exists?` predicates. This is a one-line fix per callsite that corrects the deduplication semantic without any schema change. Option A also simplifies the predicates and aligns with the `read: false` removal recommended in todo 265.

## Technical Details

- **Affected files:** `app/models/notification.rb` line 24, `app/jobs/missed_dose_check_job.rb` lines 26-33
- **Related todos:** 258 (TOCTOU race), 265 (read: false redundant in create!), 268 (deduplication index)
- **No migration needed** for Option A

## Acceptance Criteria

- [ ] `Notification.create_low_stock_for` does not re-create a low-stock notification for a medication that already has a (read) low-stock notification
- [ ] Model test added: `create_low_stock_for is a no-op when a read low_stock notification already exists for that medication`
- [ ] Existing notification model tests still pass

## Work Log

- 2026-03-11: Identified during simplicity review of Phase 19. The `read: false` in `exists?` predicate was copied from the plan document, which conflated deduplication scope with read-state filtering.
