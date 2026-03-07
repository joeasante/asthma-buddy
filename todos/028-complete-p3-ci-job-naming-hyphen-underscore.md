---
status: pending
priority: p3
issue_id: "028"
tags: [code-review, ci, quality, naming]
dependencies: []
---

# CI Job `system-test` Uses Hyphen While All Other Jobs Use Underscores

## Problem Statement

`.github/workflows/ci.yml` has five jobs with underscores (`scan_ruby`, `scan_gems`, `scan_js`, `lint`, `test`) and one with a hyphen (`system-test`). This inconsistency is cosmetic but matters for `needs:` references — any future job that depends on `system-test` must use the hyphen form exactly, and it's easy to forget.

## Findings

**Flagged by:** pattern-recognition-specialist

**Location:** `.github/workflows/ci.yml`

```yaml
jobs:
  scan_ruby:    # underscore
  scan_gems:    # underscore (new)
  scan_js:      # underscore
  lint:         # no separator
  test:         # no separator
  system-test:  # hyphen ← outlier
```

## Proposed Solutions

### Solution A: Rename to `system_test` (Recommended)

```yaml
system_test:
  runs-on: ubuntu-latest
  # ...
```
- **Pros:** Consistent with all other job names.
- **Cons:** If any external references to `system-test` job ID exist (branch protection rules, status checks), they must be updated too.
- **Effort:** Tiny
- **Risk:** Very low — check GitHub branch protection rules first

### Solution B: Leave as-is and document

Add a comment: `# Note: hyphen is intentional to match Rails convention (system-test task name)`
- **Pros:** No risk.
- **Cons:** Perpetuates inconsistency with the rest of the CI file.
- **Effort:** Tiny

## Recommended Action

Solution A. Check branch protection rules before renaming.

## Technical Details

- **Affected file:** `.github/workflows/ci.yml`
- **Check first:** GitHub repo settings → Branches → Protection rules for any reference to `system-test`

## Acceptance Criteria

- [ ] All CI job IDs use consistent separator style
- [ ] CI pipeline runs successfully after rename
- [ ] Branch protection rules updated if needed

## Work Log

- 2026-03-06: Identified by pattern-recognition-specialist during /ce:review of foundation phase changes
