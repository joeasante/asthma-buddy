---
status: pending
priority: p2
issue_id: "022"
tags: [code-review, security, ci, dependencies]
dependencies: []
---

# `bundler-audit` in CI Missing `--update` Flag — Advisory Database May Be Stale

## Problem Statement

The new `scan_gems` CI job runs `bin/bundler-audit` without the `--update` flag. Without it, bundler-audit uses a local copy of the advisory database that was bundled at install time and may be weeks or months out of date. CVEs published after the last database update will not be detected.

## Findings

**Flagged by:** kieran-rails-reviewer

**Location:** `.github/workflows/ci.yml` — `scan_gems` job, last step

```yaml
# Current — may miss recent CVEs
- name: Scan for known security vulnerabilities in gems used
  run: bin/bundler-audit
```

`bundler-audit check --update` fetches the latest advisory data from the `ruby-advisory-db` GitHub repository before scanning. Without this, the CI check is only as current as the last time the advisory database was bundled locally.

**Check what `bin/bundler-audit` does:**
```bash
cat bin/bundler-audit
# If it contains: bundle exec bundler-audit check --update
# → already correct, the CI step is fine
# If it just calls bundler-audit without --update
# → CI step needs fixing
```

## Proposed Solutions

### Solution A: Check and update the bin/bundler-audit binstub
```bash
cat bin/bundler-audit
```
If the binstub already passes `check --update`, no CI change is needed.

If not, update `.github/workflows/ci.yml`:
```yaml
- name: Scan for known security vulnerabilities in gems used
  run: bin/bundler-audit check --update
```
- **Effort:** Small
- **Risk:** None

### Solution B: Update the binstub itself
```bash
# bin/bundler-audit
#!/usr/bin/env ruby
# ...
exec Gem.bin_path('bundler-audit', 'bundler-audit'), 'check', '--update', *ARGV
```
- **Pros:** Ensures `--update` when the binstub is run locally too.
- **Effort:** Small
- **Risk:** None

## Recommended Action

Check the binstub first. If it lacks `--update`, update either the CI step or the binstub (Solution B preferred for consistency between CI and local runs).

## Technical Details

- **Affected file:** `.github/workflows/ci.yml` (and possibly `bin/bundler-audit`)
- **Check first:** `cat ~/Code/asthma-buddy/bin/bundler-audit`

## Acceptance Criteria

- [ ] Verified `bin/bundler-audit` or the CI step includes `check --update`
- [ ] CI `scan_gems` job fetches fresh advisory data on each run
- [ ] CI passes with the updated command

## Work Log

- 2026-03-06: Identified by kieran-rails-reviewer during /ce:review of foundation phase changes
