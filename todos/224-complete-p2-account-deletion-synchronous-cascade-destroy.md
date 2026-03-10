---
status: pending
priority: p2
issue_id: "224"
tags: [performance, rails, code-review, background-jobs]
dependencies: []
---

# AccountsController#destroy: Synchronous Cascade Destroy Blocks Puma Thread at Scale

## Problem Statement

`Current.user.destroy` fires synchronously in the request thread. With `dependent: :destroy` on `symptom_logs`, `health_events` (both with `has_rich_text :notes`), `medications` (which cascades to `dose_logs`), and `peak_flow_readings`, a user with significant data history will trigger 2,000–3,000+ individual SQL statements in a single synchronous chain.

At 0.5ms per SQLite write, this is 1.4–5+ seconds of blocked Puma thread time. With a small Puma thread pool (default: 3), a single account deletion can stall all concurrent requests for the duration. This will worsen as users accumulate data over time.

## Findings

**Flagged by:** performance-oracle

**Key cascade chain:**
- `symptom_logs`: N records × 2 SQL each (ActionText `has_rich_text :notes` triggers individual destroys)
- `health_events`: K records × 2 SQL each (same ActionText pattern)
- `medications`: M records → cascades to `dose_logs` (M×~200 records, per-record destroy due to `dependent: :destroy`)
- `peak_flow_readings`: P records × 1 SQL each

**Already async (not affected):**
- Solid Queue job processing
- Active Storage `purge_later`

Only the Rails ActiveRecord cascade chain is synchronous.

## Proposed Solutions

### Option A — Move deletion to AccountDeletionJob (Recommended)

Offload the destruction to a background job via Solid Queue:

```ruby
# app/controllers/accounts_controller.rb
def destroy
  user_id = Current.user.id
  terminate_session
  AccountDeletionJob.perform_later(user_id)
  redirect_to root_path, notice: "Your account is being permanently deleted. This may take a moment."
end
```

```ruby
# app/jobs/account_deletion_job.rb
class AccountDeletionJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    User.find_by(id: user_id)&.destroy
  end
end
```

**Pros:** Request thread is freed immediately (sub-10ms response). Works correctly with Solid Queue already in the stack. Scales to any data volume.
**Cons:** Requires a user-facing copy change ("being deleted" vs "deleted"). User might revisit the app briefly before deletion completes (mitigate by invalidating session immediately, which `terminate_session` already does). Requires a new job file.
**Effort:** Small–Medium
**Risk:** Low

### Option B — Swap per-record callbacks for bulk deletes where safe

Change associations without destroy callbacks to `dependent: :delete_all`, reducing SQL count by ~70%:

```ruby
# app/models/user.rb
has_many :symptom_logs,        dependent: :delete_all   # no destroy callbacks
has_many :peak_flow_readings,  dependent: :delete_all   # no destroy callbacks
has_many :personal_best_records, dependent: :delete_all # no destroy callbacks
# Keep :destroy for associations with callbacks or ActionText:
has_many :health_events,  dependent: :destroy   # has_rich_text callbacks
has_many :medications,    dependent: :destroy   # cascades to dose_logs with callbacks
```

**Pros:** No job infrastructure needed. No user-facing copy change. Significant reduction in SQL count.
**Cons:** Does not eliminate the blocking entirely — `health_events` and `medications`/`dose_logs` with ActionText still fire per-record destroys. Thread can still block for 500ms–2s on heavy users. Does not future-proof against data growth.
**Effort:** Small
**Risk:** Low — but must audit each association for destroy callbacks before switching

## Recommended Action

Option A for the long term. If Option A is deferred, apply Option B as an interim improvement. Option B can also be applied alongside Option A since `delete_all` in the job is also faster than per-record destroy.

## Technical Details

**Affected files:**
- `app/controllers/accounts_controller.rb`
- `app/models/user.rb`
- New: `app/jobs/account_deletion_job.rb` (if Option A)

**Acceptance Criteria:**
- [ ] Account deletion does not block a Puma thread for more than 500ms
- [ ] All user data is still fully deleted
- [ ] User receives appropriate feedback (immediate redirect with "being deleted" notice, or synchronous with optimized cascade)

## Work Log

- 2026-03-10: Identified by performance-oracle in Phase 16 code review.

## Resources

- Rails `dependent: :delete_all` vs `dependent: :destroy`: https://guides.rubyonrails.org/association_basics.html#dependent
- Solid Queue: https://github.com/rails/solid_queue
