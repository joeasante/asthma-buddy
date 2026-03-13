## What

<!-- One or two sentences. What does this change do? -->

## Why

<!-- Why is this change being made? Link to the issue if one exists. -->

Closes #

## Type

- [ ] Feature
- [ ] Bugfix
- [ ] Chore / refactor
- [ ] Hotfix

## Checklist

- [ ] Tests added or updated for all changed behaviour
- [ ] `bin/check` passes locally (tests, rubocop, brakeman, bundler-audit)
- [ ] Migrations are additive-safe — no column removal in same deploy as code change
- [ ] Read my own diff line-by-line before marking ready
- [ ] No secrets, credentials, or `.env` values committed
- [ ] If a migration is included: SQLite backup noted in deploy checklist
