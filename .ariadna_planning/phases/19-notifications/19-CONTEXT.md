# Phase 19: Notifications - Context

**Gathered:** 2026-03-11
**Status:** Ready for planning

<domain>
## Phase Boundary

In-app notification system: automatic creation of notifications for low medication stock and missed preventer doses; a `/notifications` feed listing all notifications newest-first; unread badge on the nav bell icon; individual and bulk mark-as-read via Turbo Stream. Peak flow reminders are excluded from this phase.

</domain>

<decisions>
## Implementation Decisions

### Trigger conditions

- **Low stock**: Created on `dose_log` save when `days_of_supply_remaining` drops below 14 for the first time in a "problem window". Does not re-fire while an unread low_stock notification for that medication already exists. Re-fires only after the user refills (count resets above threshold) and drops below again.
- **Missed dose**: Solid Queue recurring job fires at **9pm daily**. For each user's preventer medications with a `doses_per_day` schedule, check if `doses_logged_today < doses_per_day`. Create one `missed_dose` notification per medication per calendar day if not already created today. 9pm chosen so user still has ~1 hour to act.
- **Peak flow reminder**: **Dropped from Phase 19.** In-app-only reminders for "please log something" have near-zero utility without push notifications — if the user opens the app, they already know to log. Defer to a future phase alongside push/email notification preferences.

### Deduplication & frequency cap

- Rule: **one unread notification per (type, target) at a time.**
- Before creating any notification: `Notification.exists?(user:, notification_type:, notifiable:, read: false)` — if true, skip creation.
- For `missed_dose`: scope existence check to `created_at >= Date.today.beginning_of_day` — one per calendar day per medication.
- This prevents the user opening the app after several days and seeing identical repeated rows for the same problem.

### Link destinations (notifiable association)

- Store target as a **polymorphic `notifiable` association** (`notifiable_type` / `notifiable_id`) — not a raw `target_path` string. Computed paths are safer and stay valid if routes change.
- `low_stock` → `settings_medications_path` — the refill action lives there.
- `missed_dose` → dashboard (`root_path`) — Today's Doses section is on the dashboard; user logs from there.
- `system` → dashboard (safe fallback).
- **Broken target handling**: if `notifiable` record no longer exists (e.g. medication deleted), rescue `ActiveRecord::RecordNotFound`, fall back to `settings_medications_path` for medication-related types or `root_path` for others, and auto-mark the notification as read. Never 404 from a notification click.

### Notification persistence & cleanup

- Keep all notifications for **90 days**, then auto-prune via a daily Solid Queue job: `Notification.where(read: true).where("created_at < ?", 90.days.ago).delete_all`.
- **Never auto-prune unread notifications** — if the user hasn't seen it, deletion is not appropriate.
- **No individual delete in this phase** — 90-day pruning keeps the list manageable; individual delete adds UI complexity with no clear user need at this stage.

### Notification types in scope

- `low_stock` — medication below 14-day supply
- `missed_dose` — preventer dose not logged by 9pm
- `system` — general / fallback type
- ~~`peak_flow_reminder`~~ — deferred (see above)

### Claude's Discretion

- Exact Solid Queue job scheduling DSL (recurring job config)
- `relative_time_controller.js` implementation (Stimulus, updates every 60s)
- Nav bell badge implementation detail (CSS `::after` on button, driven by `data-unread-count` attribute — already specified in ROADMAP.md design rules)
- Empty state copy ("You're all caught up.")
- Notification body text wording per type

</decisions>

<specifics>
## Specific Ideas

- Polymorphic `notifiable` is preferred over `target_path` string — keeps the model clean and route-change-safe.
- The 9pm missed-dose job window is intentional: late enough to be confident the dose was skipped, early enough for the user to still act.
- The deduplication check must happen at creation time (before insert), not at display time — keeps the DB clean rather than filtering at query time.

</specifics>

<deferred>
## Deferred Ideas

- **Peak flow reminder notifications** — requires knowing the user's preferred logging time; only useful with push/email delivery; defer to a future notification preferences phase.
- **Individual notification delete** — not needed in Phase 19; add if UAT reveals demand.
- **Push / email notification delivery** — out of scope for this phase (in-app only).
- **Notification preferences / opt-out per type** — future phase.

</deferred>

---

*Phase: 19-notifications*
*Context gathered: 2026-03-11*
