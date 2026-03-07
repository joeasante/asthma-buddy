---
status: pending
priority: p2
issue_id: "052"
tags: [code-review, performance, database, sessions]
dependencies: []
---

# Session Table Accumulates Without TTL or Cleanup — Unbounded Growth

## Problem Statement

Every login creates a `sessions` row. There is no expiry column, TTL, or scheduled cleanup job. The only cleanup paths are `dependent: :destroy` (only fires on user deletion) and `terminate_session` (current session only). A user who logs in daily for a year accumulates 365+ rows. `dependent: :destroy` on sessions uses per-record Ruby destroy (not `DELETE WHERE`), so deleting a user with many stale sessions fires N individual DELETEs, potentially hitting the 5-second `busy_timeout`.

## Findings

**Flagged by:** performance-oracle (Critical)

**Location:** `app/models/user.rb:4`, `app/controllers/concerns/authentication.rb:47-51`

```ruby
# user.rb — only cleanup path is user deletion
has_many :sessions, dependent: :destroy  # fires N Ruby destroys, not one DELETE WHERE

# authentication.rb — creates a new session on every login, never prunes old ones
user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip)
```

Cookie expiry is set to 2 weeks, but nothing enforces that on the DB side. The session record lives forever.

**Performance risk on user deletion:** If a user has 10,000 sessions (malicious or power user), `dependent: :destroy` issues 10,000 sequential DELETEs in one transaction, blocking the WAL write lock.

## Proposed Solutions

### Solution A: Change to `delete_all` + add pruning job (Recommended)

```ruby
# app/models/user.rb
has_many :sessions, dependent: :delete_all  # single DELETE WHERE, no Ruby callbacks
```

Add a Solid Queue recurring job:
```ruby
# app/jobs/prune_expired_sessions_job.rb
class PruneExpiredSessionsJob < ApplicationJob
  queue_as :default

  def perform
    Session.where("created_at < ?", 2.weeks.ago).in_batches(of: 500).delete_all
  end
end
```

Add a migration:
```ruby
add_index :sessions, :created_at  # needed for efficient range delete
```

Configure the recurring job in `config/solid_queue.yml`.

- **Effort:** Medium
- **Risk:** Low — `delete_all` safe since `Session` has no destroy callbacks

### Solution B: Add `expires_at` column and check on resume

```ruby
# Migration: add_column :sessions, :expires_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP + INTERVAL 14 DAYS" }
# Resume check:
def find_session_by_cookie
  Session.find_by(id: cookies.signed[:session_id])&.then { |s| s.expires_at > Time.current ? s : nil }
end
```

- **Pros:** Explicit expiry stored on the record
- **Effort:** Medium
- **Risk:** Low

## Technical Details

- **Migration needed:** `add_index :sessions, :created_at`
- **New job:** `app/jobs/prune_expired_sessions_job.rb`
- **Config:** Solid Queue recurring schedule in `config/solid_queue.yml`

## Acceptance Criteria

- [ ] `has_many :sessions` uses `dependent: :delete_all`
- [ ] Sessions older than 2 weeks are pruned periodically
- [ ] `created_at` index exists on the sessions table
- [ ] Pruning runs in batches to avoid long write locks

## Work Log

- 2026-03-07: Created from performance review. performance-oracle Priority 1-2.
