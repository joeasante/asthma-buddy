---
phase: 19-notifications
plan: 01
completed_at: 2026-03-11T09:37:15Z
duration_seconds: 185
tasks_completed: 2
tasks_total: 2
files_created: 6
files_modified: 3
tests_added: 12
tests_total: 451
---

# Plan 19-01 Summary: Notification Data Layer

## Objective

Build the Notification data layer: model, migration, fixtures, model tests, the low-stock trigger on DoseLog, and two background jobs (MissedDoseCheckJob + PruneNotificationsJob) with their recurring schedules.

## Tasks Completed

### Task 1: Notification migration, model, fixtures, and model tests

**Status:** Complete (commit ef8eef1)

Created the full Notification data contract:

- **Migration** (`db/migrate/20260311093356_create_notifications.rb`): Creates `notifications` table with `user_id` (references, NOT NULL, FK), `notifiable_type` (string, nullable), `notifiable_id` (integer, nullable), `notification_type` (integer, NOT NULL), `body` (string, NOT NULL), `read` (boolean, default false, NOT NULL), timestamps. Composite indexes on `[user_id, read]` and `[notifiable_type, notifiable_id]`.

- **Model** (`app/models/notification.rb`): `belongs_to :user`, `belongs_to :notifiable, polymorphic: true, optional: true`, `enum :notification_type { low_stock: 0, missed_dose: 1, system: 2 }` with `validate: true`. Scopes: `unread`, `newest_first`, `pruneable`. Class method `create_low_stock_for(medication)` with medication.low_stock? guard and unread-deduplication.

- **Fixtures** (`test/fixtures/notifications.yml`): 4 fixtures — `alice_low_stock`, `alice_missed_dose`, `alice_read_old` (91 days ago, read=true, for pruning tests), `bob_notification` (cross-user isolation). Polymorphic `notifiable_id` set via `ActiveRecord::FixtureSet.identify`.

- **Tests** (`test/models/notification_test.rb`): 12 tests covering valid save, notification_type validation, body validation, unread scope, newest_first scope, pruneable scope (3 cases), create_low_stock_for creates, create_low_stock_for no-op when not low_stock?, create_low_stock_for deduplication.

### Task 2: DoseLog callback, jobs, and recurring schedule

**Status:** Complete (commit 89c718a)

- **DoseLog callback** (`app/models/dose_log.rb`): Added `after_create_commit :check_low_stock` private method that calls `Notification.create_low_stock_for(medication)`. Fires only on create — covers every dose log creation without touching update/destroy paths.

- **MissedDoseCheckJob** (`app/jobs/missed_dose_check_job.rb`): Iterates `Medication.non_courses.where(medication_type: :preventer).where.not(doses_per_day: nil)` using `find_each` (batch processing, avoids memory spike). For each medication, counts `DoseLog` records for today. If count < doses_per_day, checks for existing unread missed_dose notification today before creating one. Deduplication via `Notification.exists?` with `created_at` range.

- **PruneNotificationsJob** (`app/jobs/prune_notifications_job.rb`): Single-line `Notification.pruneable.delete_all`. Uses model scope (`read=true AND created_at < 90.days.ago`). Never touches unread notifications.

- **config/recurring.yml**: Added `missed_dose_check` (MissedDoseCheckJob, every day at 9pm) and `prune_notifications` (PruneNotificationsJob, every day at 3am) under the `production:` block.

- **User model** (`app/models/user.rb`): Added `has_many :notifications, dependent: :delete_all` — required to prevent FK constraint failure when a user account is deleted. Follows existing `delete_all` pattern for associations without destroy callbacks.

## Files Created

| File | Purpose |
|------|---------|
| `db/migrate/20260311093356_create_notifications.rb` | Notifications table migration |
| `app/models/notification.rb` | Notification model with enum, scopes, create_low_stock_for |
| `test/fixtures/notifications.yml` | 4 test fixtures |
| `test/models/notification_test.rb` | 12 model tests |
| `app/jobs/missed_dose_check_job.rb` | Daily preventer missed-dose check job |
| `app/jobs/prune_notifications_job.rb` | Daily pruning of old read notifications |

## Files Modified

| File | Change |
|------|--------|
| `app/models/dose_log.rb` | Added after_create_commit :check_low_stock |
| `config/recurring.yml` | Added MissedDoseCheckJob + PruneNotificationsJob schedules |
| `app/models/user.rb` | Added has_many :notifications, dependent: :delete_all |
| `db/schema.rb` | Updated by migration (notifications table) |

## Key Decisions

1. **notifiable columns nullable**: The plan specifies `optional: true` on the polymorphic `belongs_to :notifiable` because the notifiable record may be deleted (e.g. medication removed). Accordingly, `notifiable_type` and `notifiable_id` DB columns are also nullable — a NOT NULL constraint would prevent creating system notifications without a notifiable and would cause constraint errors after the target record is deleted.

2. **`validate: true` enum behavior**: With `validate: true`, Rails enum routes unknown values to validation errors rather than raising `ArgumentError`. The test for this was updated to assert `notification.errors[:notification_type].any?` for the nil case and `assert_not notification.valid?` for the invalid string case — consistent with how Rails 7+ enum validation works.

3. **`has_many :notifications, dependent: :delete_all` on User**: The FK constraint on `notifications.user_id` caused `FOREIGN KEY constraint failed` errors in 3 AccountsControllerTest cases when destroying a user. Added `dependent: :delete_all` (same pattern as sessions, peak_flow_readings, dose_logs — no callbacks on notifications). Auto-fixed as Rule 1 (blocking regression).

4. **`find_each` in MissedDoseCheckJob**: Production could have many medications. `find_each` processes in batches of 1000 by default, avoiding a full AR object load for all medications at once.

5. **MissedDoseCheckJob deduplication via `created_at` range**: The `Notification.exists?` check scopes to `created_at: today.beginning_of_day..today.end_of_day` — one notification per calendar day per medication. The job can be re-run safely without creating duplicates.

## Deviations from Plan

1. **[Rule 1 - Bug] notifiable_type/notifiable_id columns made nullable**: Plan spec said `null: false` for both columns. Changed to nullable because: (a) `optional: true` on the belongs_to requires the DB to allow null for the FK constraint not to fire after target deletion; (b) inline test creates in pruneable tests would fail with NOT NULL constraint when creating system notifications without a notifiable. The plan's own rationale for `optional: true` ("notifiable record may have been deleted") makes nullable columns the correct implementation.

2. **[Rule 1 - Bug] Added `has_many :notifications, dependent: :delete_all` to User**: Not mentioned in the plan's files_modified list. Necessary to prevent FOREIGN KEY constraint failure on user account deletion (AccountsControllerTest regression). Follows the established pattern.

3. **[Rule 1 - Test] enum validation test adjusted**: Plan test #2 specified "invalid type raises error" — with `validate: true`, this produces a validation error not an exception. Tests updated to correctly verify the Rails 7+ validate: true behavior.

## Test Results

- Tests added: 12 (all model tests for Notification)
- Total tests: 451 (up from 421 at Phase 18-03 close, +30 from Phase 18 uncommitted changes + 12 new = correctly 451)
- Regressions: 0
- Full suite: 451 runs, 1181 assertions, 0 failures, 0 errors, 0 skips

## Commits

| Hash | Description |
|------|-------------|
| ef8eef1 | feat(19-01): Notification model, migration, fixtures, and model tests |
| 89c718a | feat(19-01): DoseLog low-stock callback, MissedDoseCheckJob, PruneNotificationsJob, recurring schedule |

## Self-Check: PASSED

All created files verified present. All commits verified in git log. 451 tests passing, 0 regressions.
