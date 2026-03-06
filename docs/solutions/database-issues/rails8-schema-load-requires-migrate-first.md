---
title: "db:schema:load fails on fresh Rails app due to missing schema.rb"
date: "2026-03-06"
category: "database-issues"
tags:
  - rails
  - database
  - setup
  - initialization
  - schema
symptoms:
  - "db:schema:load aborts on a fresh Rails application"
  - "schema.rb file does not exist in db/ directory"
  - "Fresh app setup fails during database initialization"
environment: "Rails 8.1.2, SQLite3, fresh application setup"
related_files:
  - db/schema.rb
  - config/database.yml
---

# db:schema:load fails on fresh Rails app

## Symptom

Running `bin/rails db:schema:load` on a brand new Rails app fails because `db/schema.rb` doesn't exist yet.

## Root Cause

`db/schema.rb` is auto-generated the first time you run `bin/rails db:migrate`. On a fresh app with no migrations ever run, the file doesn't exist — so `db:schema:load` has nothing to load.

## Fix

Run `db:migrate` first to generate `schema.rb`, then `db:schema:load` will succeed:

```bash
bin/rails db:migrate      # generates db/schema.rb
bin/rails db:schema:load  # now succeeds
```

Or use `db:prepare`, which handles both cases automatically (creates DB if missing, runs migrations or loads schema as appropriate):

```bash
bin/rails db:prepare
```

## Prevention

- Commit `db/schema.rb` to version control after the first migration so CI/CD can always use `db:schema:load`.
- Prefer `bin/rails db:prepare` over `db:schema:load` in CI pipelines — it works on both fresh and existing setups.

## Verification

```bash
ls db/schema.rb            # should exist after migrate
bin/rails db:schema:load   # should exit 0
```

---
*Encountered during Phase 01-foundation — 2026-03-06*
