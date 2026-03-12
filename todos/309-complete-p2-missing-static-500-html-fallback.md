---
status: complete
priority: p2
issue_id: 309
tags: [code-review, rails, error-handling]
---

# 309 — P2 — Missing static `public/500.html` and `public/404.html` fallback files

## Problem Statement

`public/404.html` and `public/500.html` were deleted as part of the move to a custom `ErrorsController` via `config.exceptions_app`. These static files serve as Rails' last-resort fallback: if `ErrorsController` itself raises a secondary exception (e.g. a database outage causes `ApplicationController` before-actions to fail), Rails falls back to the static file at `public/{status}.html`. Since those files no longer exist, a secondary exception produces a bare, unstyled response with no helpful content for the user.

The current codebase does have `public/400.html`, `public/422.html`, and `public/406-unsupported-browser.html`, confirming the `public/` pattern is understood and intentional for other status codes — the 500 and 404 slots were simply not repopulated after the `ErrorsController` migration.

## Findings

- `public/404.html` — absent
- `public/500.html` — absent
- `config/application.rb` sets `config.exceptions_app = self.routes` — all exceptions are routed through `ErrorsController`
- `ErrorsController` inherits from `ApplicationController` (see also Todo 306), meaning any failure in `ApplicationController` (before-actions, session lookup, etc.) will prevent the custom error views from rendering
- When the secondary exception occurs, Rails looks for `public/{status}.html`; if absent it emits a minimal, completely unstyled HTML stub — no branding, no navigation, no recovery link
- The 500 scenario is the highest-risk case: if the original exception was caused by a database outage, the `ApplicationController` before-action that calls `resume_session` will itself query the database and raise again (see also Todo 308), triggering the fallback path
- `public/400.html`, `public/422.html`, and `public/406-unsupported-browser.html` are present — 500 and 404 are the missing slots

**Affected directory:** `public/`

## Proposed Solutions

### Option A — Add minimal styled static fallbacks (recommended)

Add `public/500.html` and `public/404.html` as self-contained static HTML files with inline CSS. They do not need to match the full application design — their only job is to communicate that something went wrong and provide a recovery link to `/`. Keep them under ~5 KB each so they remain dependency-free and guaranteed to load even if the asset pipeline is unavailable.

These files are never shown under normal operation; they are purely a safety net for the double-fault scenario.

### Option B — Add bare-minimum plaintext fallbacks

If design consistency is not a concern for the fallback, create `public/500.html` and `public/404.html` as minimal HTML with no CSS — just a heading, a short message, and a link to `/`. Faster to produce; less user-friendly if displayed.

### Option C — Fix the root cause instead (address alongside)

Fix `ErrorsController` so it does not inherit from `ApplicationController` (Todo 306) and remove the DB-querying `authenticated?` calls from error views (Todo 308). This greatly reduces the probability of hitting the double-fault path and may be sufficient on its own — but static fallbacks remain best practice regardless and should be added as a belt-and-suspenders measure.

## Acceptance Criteria

- [ ] `public/500.html` exists and is a valid, self-contained HTML document
- [ ] `public/404.html` exists and is a valid, self-contained HTML document
- [ ] Both files include a human-readable error message and a link to `/`
- [ ] Both files load correctly in a browser without any external dependencies (no CDN, no asset pipeline)
- [ ] The files are not reachable under normal application operation (the `ErrorsController` route continues to handle exceptions first)
- [ ] A comment in the file or a nearby README note explains the purpose of these files so they are not deleted again

## Technical Details

| Field | Value |
|---|---|
| Affected directory | `public/` |
| Missing files | `public/500.html`, `public/404.html` |
| Root cause | Static fallbacks removed during `ErrorsController` migration; not repopulated |
| Failure mode | Secondary exception in `ErrorsController` → Rails seeks `public/{status}.html` → file absent → bare unstyled stub |
| Severity | P2 — only reached via double-fault; low probability but zero mitigation currently |
| Related issues | Todo 306 (`ErrorsController` inherits `ApplicationController`), Todo 308 (DB query in 500 view) |
| Existing precedent | `public/400.html`, `public/422.html`, `public/406-unsupported-browser.html` all present |
