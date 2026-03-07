---
status: pending
priority: p3
issue_id: "013"
tags: [code-review, security, ci, supply-chain]
dependencies: []
---

# `ruby/setup-ruby` GitHub Action Not Pinned to Commit SHA

## Problem Statement

`.github/workflows/ci.yml` uses `ruby/setup-ruby@v1` (floating mutable tag) in all 5 jobs. A compromised `ruby/setup-ruby` repository or force-pushed `v1` tag would silently execute attacker-controlled code in CI with access to all workflow secrets. `actions/checkout` was correctly fixed from `@v6` to `@v4` but left as a floating tag; `ruby/setup-ruby` has the same issue.

## Findings

**Flagged by:** security-sentinel (LOW)

**Location:** `.github/workflows/ci.yml` — `uses: ruby/setup-ruby@v1` appears 5 times

## Proposed Solutions

### Option A — Pin to full commit SHA + add Dependabot for Actions (Recommended)
```yaml
uses: ruby/setup-ruby@a2bbe5b1924ea5745f98bf10ee80b9ba7d38e3b6  # v1.x.y
```

Add `.github/dependabot.yml`:
```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
```

**Effort:** Small
**Risk:** None

### Option B — Leave as floating tag
Accept the supply chain risk for now.

**Effort:** None
**Risk:** Low (but real for a health app)

## Recommended Action

Option A — pin all actions and add Dependabot.

## Technical Details

**Affected files:**
- `.github/workflows/ci.yml`
- `.github/dependabot.yml` (new)

**Acceptance Criteria:**
- [ ] `ruby/setup-ruby` pinned to full commit SHA
- [ ] `actions/checkout` pinned to full commit SHA
- [ ] `.github/dependabot.yml` configured for `github-actions`

## Work Log

- 2026-03-06: Identified by security-sentinel.
