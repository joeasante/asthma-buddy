---
status: complete
priority: p1
issue_id: 308
tags: [code-review, rails]
---

# 308 — P1 — `internal_server_error` view calls `authenticated?` which queries the database

## Problem Statement

`app/views/errors/internal_server_error.html.erb` calls `authenticated?`, which internally calls `resume_session`, which issues a database query to look up the current session.

If the original 500 error was caused by a database failure, this view-level call will raise a secondary exception. The 500 page is the one place in the application where a DB query in the view is most likely to itself fail — creating a double-fault scenario that results in no styled error page being served.

The 404 view has the same pattern but at lower risk, since 404s are not commonly caused by database failures.

## Findings

- `app/views/errors/internal_server_error.html.erb` calls `authenticated?`
- `authenticated?` calls `resume_session` (defined in `SessionsHelper` or `Authentication` concern)
- `resume_session` issues a `SELECT` query against the sessions table
- No rescue wrapper exists at the view or controller level to catch a secondary ActiveRecord exception
- If the secondary exception is raised, Rails falls back to `public/500.html`, which does not exist (see also Todo 306), producing a bare Rails error page
- The 404 view has the same `authenticated?` call — lower severity but worth fixing in the same pass

**Affected files:**
- `app/views/errors/internal_server_error.html.erb`
- `app/views/errors/not_found.html.erb` (same pattern, lower risk)

## Proposed Solutions

### Option A — Remove `authenticated?` from the 500 view entirely (recommended)

A user who has just hit a server error does not need personalised navigation. Replace any authenticated-gated content on the 500 page with a single unconditional link to `root_path`. This is the simplest fix and the correct user experience for a 500 page — do not attempt session lookups on a page that exists to handle catastrophic failure.

```erb
<%= link_to "Back to home", root_path %>
```

### Option B — Wrap `authenticated?` in a rescue
Guard the call so a secondary exception is swallowed and the page degrades gracefully:

```erb
<% is_authenticated = begin; authenticated?; rescue; false; end %>
```

This preserves the current conditional rendering behaviour while preventing a double-fault. However, it leaves a DB query in the hot path for every 500 page render — a noise source that makes it harder to spot real errors.

### Option C — Expose a controller-assigned instance variable
In `ErrorsController#internal_server_error`, attempt the session lookup once and assign a boolean to an instance variable (`@authenticated`), wrapping it in a rescue. The view reads only the instance variable — no DB access in the view layer. More architecturally clean than option B but more code than option A.

## Acceptance Criteria

- [ ] `app/views/errors/internal_server_error.html.erb` does not call `authenticated?` (or any method that issues a DB query) at the top level
- [ ] The 500 page renders correctly when the database is unavailable (can be verified by stubbing ActiveRecord to raise)
- [ ] The 500 page provides a usable recovery path for the user (e.g. a link back to the home page)
- [ ] The same fix is applied to `app/views/errors/not_found.html.erb` for consistency
- [ ] Existing error page rendering tests (if any) continue to pass; new test added for the DB-down scenario

## Technical Details

| Field | Value |
|---|---|
| Primary affected file | `app/views/errors/internal_server_error.html.erb` |
| Secondary affected file | `app/views/errors/not_found.html.erb` |
| Root cause | `authenticated?` → `resume_session` → DB query inside the 500 error view |
| Failure mode | Secondary ActiveRecord exception on DB outage → fallback to `public/500.html` → file missing → bare Rails page |
| Severity | P1 — view-level DB query on the one page most likely to be triggered by a DB failure |
| Related issue | Todo 306 addresses the same DB query risk at the controller before_action level |
