---
status: pending
priority: p2
issue_id: "069"
tags: [code-review, rails, quality]
dependencies: []
---

# `_personal_best_form` Partial Reads `@current_personal_best` Instance Variable Instead of Local

## Problem Statement

`app/views/settings/_personal_best_form.html.erb` accesses `@current_personal_best` directly as an instance variable rather than receiving it as a local. Every other partial in this codebase receives its data through locals. This breaks the "partials are self-contained" convention and creates a hidden coupling to `SettingsController`.

## Findings

**Flagged by:** kieran-rails-reviewer, pattern-recognition-specialist

**Location:** `app/views/settings/_personal_best_form.html.erb:30`

```erb
<%= form.submit @current_personal_best ? "Update personal best" : "Set personal best" %>
```

The partial is rendered from `show.html.erb`:
```erb
<%= render "personal_best_form", personal_best_record: @personal_best_record %>
```

`@current_personal_best` is not passed as a local — the partial reaches into the controller namespace.

**Why this matters:**
- If this partial is ever rendered from a different context (e.g., a mailer preview, a test helper), `@current_personal_best` will be nil and the button will silently say "Set personal best" even when a record exists
- It violates the convention established by every other partial in the codebase
- It makes the partial untestable in isolation

## Proposed Solution

Pass `current_personal_best` as a local when rendering the partial:

```erb
<%# app/views/settings/show.html.erb %>
<%= render "personal_best_form",
      personal_best_record: @personal_best_record,
      current_personal_best: @current_personal_best %>
```

In the partial, use the local:

```erb
<%# app/views/settings/_personal_best_form.html.erb %>
<%= form.submit current_personal_best ? "Update personal best" : "Set personal best" %>
```

**Effort:** XSmall (2 file changes, 2 lines)
**Risk:** Zero

## Acceptance Criteria

- [ ] `current_personal_best` passed as local in `show.html.erb` render call
- [ ] `_personal_best_form.html.erb` uses local `current_personal_best`, not `@current_personal_best`
- [ ] All 142 existing tests still pass

## Work Log

- 2026-03-07: Identified by kieran-rails-reviewer and pattern-recognition-specialist during Phase 6 code review
