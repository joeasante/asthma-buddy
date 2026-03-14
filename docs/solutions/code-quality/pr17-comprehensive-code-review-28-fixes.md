---
title: "PR #17 Comprehensive Code Review: 28 Fixes Across Security, Performance & Quality"
problem_type: code_quality
modules: [authentication, admin, medications, rate_limiting, health_report, sessions, migrations]
tags: [code-review, security, performance, sqlite, rack-attack, stimulus, json-api, migrations]
severity: mixed
date_solved: 2026-03-14
---

# PR #17 Comprehensive Code Review — 28 Fixes

## Problem

After merging PR #17 (Phases 23-25: Security, Admin, Clinical Intelligence & Access Control), a multi-agent code review identified 28 issues ranging from critical security gaps to nice-to-have improvements. Issues spanned authentication, admin panel, rate limiting, database migrations, API parity, and frontend patterns.

## Symptoms

- `skip_before_action :check_session_freshness` proliferating across 9 controllers
- Race condition in admin toggle (TOCTOU vulnerability)
- Non-atomic sign-in counter increment
- Missing database constraints for dose_unit and admin columns (SQLite schema dump limitation)
- Inline `onclick="window.print()"` handlers instead of Stimulus
- No JSON API responses for agent/API consumers
- Admin mailer leaking user email in subject line
- Missing indexes on admin query columns

## Root Cause Analysis

### 1. SQLite Schema Dump Limitation (Critical)
When using `add_column` with `default:` and `null: false` in SQLite, Rails backfills values but doesn't persist the NOT NULL and DEFAULT constraints in the schema metadata. This means `db:schema:load` on a fresh database creates columns without those constraints.

**Fix:** Created `20260314140300_fix_null_and_default_constraints.rb` using `change_column_null` and `change_column_default` after backfilling NULL values.

### 2. Session Freshness Skip Proliferation
Nine controllers had `skip_before_action :check_session_freshness` because the filter ran on unauthenticated routes (login, signup, password reset).

**Fix:** Changed to `before_action :check_session_freshness, if: :authenticated?` in ApplicationController, eliminating all 9 skip declarations.

### 3. TOCTOU Race in Admin Toggle
The admin toggle checked `user.admin?` then toggled the value in two separate operations, allowing a race condition.

**Fix:** Wrapped in `User.transaction` block. SQLite serializes writes, making this safe.

### 4. Non-Atomic Sign-In Counter
`user.update!(sign_in_count: user.sign_in_count + 1)` reads stale value under concurrent requests.

**Fix:** `User.where(id: user.id).update_all("sign_in_count = sign_in_count + 1")` — atomic SQL increment.

### 5. Rack::Attack Missing Account-Level Throttle
Only IP-based throttling existed. Distributed brute-force attacks from multiple IPs against a single account were unprotected.

**Fix:** Added `logins/email` throttle (10 per 5 minutes) keyed on normalized email. Added format-aware 429 responses (JSON vs plain text based on Accept header). Uses `Rails.cache` (Solid Cache/SQLite) in production, `MemoryStore` in test.

### 6. Dose Unit Data Integrity
Medications with type `other` (3) and `tablet` (4) had `dose_unit = 'puffs'` — incorrect default.

**Fix:** Backfill migration + CHECK constraint: `dose_unit IN ('puffs', 'tablets', 'ml')`.

### 7. Missing JSON API Parity
Admin dashboard, admin users, health report, and dashboard controllers lacked JSON responses — agents couldn't consume the data programmatically.

**Fix:** Added `respond_to` blocks with `format.json` across all affected controllers.

## Working Solution

All 28 fixes applied across these categories:

| Category | Count | Key Changes |
|----------|-------|-------------|
| Security | 6 | Session freshness, TOCTOU fix, atomic counter, email throttle, admin audit logging, mailer subject |
| Database | 5 | Dose unit backfill, CHECK constraint, NULL/DEFAULT constraints, admin indexes, pagination limit |
| API Parity | 5 | JSON responses for admin dashboard, users, health report, main dashboard, session expiry |
| Code Quality | 7 | Skip removal (9 controllers), Stimulus print controller, model constants, dose_unit_label fix |
| Performance | 3 | Admin query indexes, pagination limit, stale threshold constant |
| Architecture | 2 | Format-aware 429 responses, access_restricted? method removal |

### Key Files Modified

- `app/controllers/application_controller.rb` — session freshness guard
- `app/controllers/sessions_controller.rb` — atomic sign-in counter
- `app/controllers/admin/users_controller.rb` — transaction, pagination, JSON
- `app/controllers/admin/base_controller.rb` — audit logging, JSON 403
- `config/initializers/rack_attack.rb` — account throttle, format-aware responses
- `app/models/medication.rb` — dose_unit_label fix for "ml"
- `app/javascript/controllers/print_controller.js` — new Stimulus controller
- 4 new migrations for data integrity

### Verification

```
576 tests, 0 failures, 0 errors
RuboCop: no offenses
Browser tests: 10 pages, all passing
```

## Prevention Strategies

1. **SQLite schema constraint drift**: After any migration adding `null: false` or `default:`, run `db:schema:dump` and inspect the output. If constraints are missing, add explicit `change_column_null` / `change_column_default` calls. Add model-level `validates :col, presence: true` as a second line of defense.

2. **Global before_action skip proliferation**: Use `if: :authenticated?` guards instead of forcing every unauthenticated controller to opt out. Better yet, use a base `AuthenticatedController` so the security boundary is visible in the class hierarchy.

3. **TOCTOU race on count-check-then-update**: Never read a count in Ruby and conditionally write. Wrap in a transaction with locking, or use database-level constraints. Flag all `if record.count < N` then `record.create` patterns in review.

4. **Non-atomic counter increments**: Ban `update_columns` with manual `+= 1`. Use `update_all` with SQL expression, `increment!`, or `counter_cache`. Consider a CI grep that flags `update_columns` on `_count` columns.

5. **Rack::Attack MemoryStore in multi-worker**: `MemoryStore` is per-process — useless for rate limiting with Puma workers > 0. Always use `Rails.cache` (Solid Cache/SQLite-backed) in production.

6. **JSON API parity**: Treat API coverage as definition-of-done. Every `format.html` action must also `respond_to :json`. Consider a CI test that hits all GET routes with `Accept: application/json` and asserts non-406.

7. **No inline JavaScript**: Prohibit `onclick`, `onsubmit`, and all `on*` HTML attributes. Every behavior must be a Stimulus controller with `data-action`. A CI grep for `on\w+=` in templates catches violations.

8. **PII in email subjects**: Subjects must never contain names, emails, or health data — they appear in mail server logs, notification previews, and feedback loops. Use generic subjects; put personalized content in the body.

9. **Polymorphic backfill safety**: When adding a column to a table with multiple types, never use a blanket `default:`. Add nullable, write a type-specific data migration, then add `null: false` constraint separately.

## Related Documentation

### SQLite & Migrations
- `docs/solutions/database-issues/rails8-schema-load-requires-migrate-first.md` — `db:schema:load` fails on fresh Rails 8.1.2 when schema.rb doesn't exist
- `todos/348-complete-p1-schema-rb-missing-constraints-dose-unit-admin.md` — The original finding

### Security & Authorization
- `docs/solutions/security-issues/authorization-scope-bypass-via-wrong-parent-association.md` — Authorization bypass pattern
- `docs/solutions/security-issues/terminate-session-vs-reset-session-account-deletion.md` — Session handling during account deletion
- `todos/351-complete-p1-toggle-admin-toctou-race-condition.md` — TOCTOU race finding
- `todos/258-complete-p1-notification-deduplication-toctou-race.md` — Related TOCTOU pattern in notifications

### Rate Limiting
- `todos/355-complete-p2-rack-attack-memory-store-not-shared.md` — MemoryStore finding
- `todos/367-complete-p3-rack-attack-account-level-throttle.md` — Account-level throttle finding

### JSON API Parity (Recurring Pattern)
- `todos/008-complete-p2-no-json-response-convention.md` — Original convention gap
- `todos/271-complete-p1-dashboard-no-json-api.md` — Dashboard JSON gap
- `todos/358-complete-p2-missing-json-api-health-report-admin.md` — Health report JSON gap

### PII & PHI Protection
- `todos/366-complete-p3-admin-mailer-pii-in-subject.md` — Mailer PII finding
- `todos/321-complete-p1-phi-fields-not-filtered-from-logs.md` — PHI in Rails logs
- `todos/036-complete-p2-json-auth-user-enumeration.md` — User enumeration via JSON auth

### Source PR
- [PR #17](https://github.com/josephasante/asthma-buddy/pull/17) — Phases 23-25: Security, Admin, Clinical Intelligence & Access Control
