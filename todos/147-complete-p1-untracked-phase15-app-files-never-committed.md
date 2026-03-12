---
status: pending
priority: p1
issue_id: "147"
tags: [code-review, git, process, health-events]
dependencies: []
---

# Untracked Phase 15 App Files Never Committed

## Problem Statement

The core Phase 15 implementation files exist on disk but are NOT tracked by git. If a fresh clone is checked out, the app will be missing its model, controller, views, migrations, CSS, and Stimulus controller for Health Events — the feature will not exist in the codebase. The tests will fail because they reference non-existent files.

## Findings

**Flagged by:** Manual inspection (orchestrator), confirmed by `git status --short`

**Untracked files discovered:**
```
?? app/assets/stylesheets/health_events.css
?? app/controllers/health_events_controller.rb
?? app/javascript/controllers/end_date_controller.js
?? app/models/health_event.rb
?? app/views/health_events/
?? db/migrate/20260309000001_create_health_events.rb
?? db/migrate/20260309000002_add_ended_at_to_health_events.rb
```

Also untracked (planning docs):
```
?? .ariadna_planning/phases/15-health-events/15-01-PLAN.md
?? .ariadna_planning/phases/15-health-events/15-02-PLAN.md
?? .ariadna_planning/phases/15-health-events/15-03-PLAN.md
?? .ariadna_planning/phases/15-health-events/15-CONTEXT.md
```

The executor agents committed test files (`test/fixtures/health_events.yml`, `test/models/health_event_test.rb`, etc.) but never committed the app implementation files. The tests pass because the files exist on disk, not because they are in git.

## Proposed Solutions

### Option A — Commit all missing files in one commit (Recommended)
Stage and commit all untracked Phase 15 app files. The commit should be atomic: model + controller + views + migrations + CSS + JS controller + planning docs.

**Pros:** Simple, correct, complete.
**Cons:** None — this is just catching up on a missed commit.
**Effort:** Small
**Risk:** None

### Option B — Squash migrations first, then commit
First squash the two health_events migrations into one (see todo 150), then commit all files in a single clean commit.

**Pros:** Migration history is clean at the same time.
**Cons:** Requires a bit more work (squash migration, re-run `db:migrate`).
**Effort:** Small–Medium
**Risk:** Low

## Recommended Action

Option A immediately, then Option B when todo 150 is worked. Or do B right now — squash the migrations, then commit everything.

## Technical Details

**Files to stage:**
```bash
git add app/models/health_event.rb
git add app/controllers/health_events_controller.rb
git add app/views/health_events/
git add app/assets/stylesheets/health_events.css
git add app/javascript/controllers/end_date_controller.js
git add db/migrate/20260309000001_create_health_events.rb
git add db/migrate/20260309000002_add_ended_at_to_health_events.rb
git add .ariadna_planning/phases/15-health-events/
```

## Acceptance Criteria

- [ ] `git ls-files app/models/health_event.rb` returns the file path (not empty)
- [ ] `git ls-files app/controllers/health_events_controller.rb` returns the file path
- [ ] `git ls-files app/views/health_events/` returns all 6 view files
- [ ] `git ls-files db/migrate/ | grep health_event` returns the migration(s)
- [ ] `git status --short | grep "^??"` shows no Phase 15 app files as untracked
- [ ] `bin/rails test` still passes after commit

## Work Log

- 2026-03-09: Identified during `ce:review` of Phase 15. Core app files exist on disk but not in git.

## Resources

- `git status --short` output showing untracked files
- Phase 15 execution commit log: `git log --oneline HEAD~10..HEAD`
