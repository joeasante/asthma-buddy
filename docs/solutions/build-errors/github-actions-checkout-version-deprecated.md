---
title: "GitHub Actions uses actions/checkout@v6 which doesn't exist"
date: "2026-03-06"
category: "build-errors"
tags:
  - github-actions
  - ci
  - rails
  - checkout
symptoms:
  - "CI pipeline fails at checkout step"
  - "Unable to resolve action — release not found"
  - "Rails generated ci.yml uses @v6 which is not a valid version"
environment: "GitHub Actions, Rails 8 generated CI template"
related_files:
  - .github/workflows/ci.yml
---

# GitHub Actions uses actions/checkout@v6 (doesn't exist)

## Symptom

The Rails 8 generated `.github/workflows/ci.yml` references `actions/checkout@v6` across all CI jobs. Version 6 does not exist — valid versions are v1–v4. The pipeline fails or uses a broken reference.

## Root Cause

The default Rails 8 CI template shipped with an incorrect action version (`@v6`). The current stable release is `@v4`.

## Fix

Replace all occurrences of `actions/checkout@v6` with `actions/checkout@v4` in `.github/workflows/ci.yml`:

```yaml
# Before (incorrect)
- uses: actions/checkout@v6

# After (correct)
- uses: actions/checkout@v4
```

There are typically 5 jobs in the Rails CI template, each with their own `checkout` step — update all of them.

## Prevention

- When generating a new Rails app, immediately audit the generated `ci.yml` for action versions.
- Add Dependabot for GitHub Actions to keep versions current:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

## Verification

```bash
grep "actions/checkout" .github/workflows/ci.yml
# All lines should show @v4
```

---
*Encountered during Phase 01-foundation — 2026-03-06*
