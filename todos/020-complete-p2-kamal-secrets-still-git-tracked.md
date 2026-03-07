---
status: pending
priority: p2
issue_id: "020"
tags: [code-review, security, git, kamal, secrets]
dependencies: []
---

# `.kamal/secrets` Still Tracked in Git History

## Problem Statement

`.kamal/secrets` was added to `.gitignore` in this changeset, but `git status` shows the file as modified (not untracked), meaning it was previously committed and is still tracked. Adding to `.gitignore` stops future tracking but does not remove the file from git history. Additionally, the file must be untracked with `git rm --cached` or it will continue to appear in `git status` output.

## Findings

**Flagged by:** security-sentinel (F-07)

**Evidence:**
```bash
# git status shows:
 M .github/workflows/ci.yml   # modified — was tracked
# .kamal/secrets is in git status as modified, not as untracked
```

The current `.kamal/secrets` content:
```bash
KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD
RAILS_MASTER_KEY=$RAILS_MASTER_KEY
```

These are shell variable references (not raw values), which limits direct exposure. But:
1. The git history reveals which secrets are used (`KAMAL_REGISTRY_PASSWORD`, `RAILS_MASTER_KEY`) — aids targeted attacks.
2. A previous version of the file may have contained raw credentials during initial setup.
3. The file must be explicitly untracked or `git status` will keep showing it as modified.

## Proposed Solutions

### Solution A: Untrack file and audit history (Recommended)
```bash
# 1. Untrack without deleting from disk
git rm --cached .kamal/secrets

# 2. Audit full history for raw credentials
git log --all --follow -p -- .kamal/secrets

# 3. If raw credentials found: rotate them, then use git filter-repo to purge
# pip install git-filter-repo
# git filter-repo --path .kamal/secrets --invert-paths

# 4. Commit the .gitignore change + the untracking
git add .gitignore
git commit -m "chore: untrack .kamal/secrets"
```
- **Pros:** Correctly untrack the file, audit for historical credential exposure.
- **Effort:** Small
- **Risk:** Low if no raw credentials found in history; Medium if rotation required

### Solution B: Full history purge proactively
Run `git filter-repo` regardless of whether raw credentials were found — eliminates all traces.
- **Pros:** Belt-and-suspenders.
- **Cons:** Rewrites git history (requires force-push to remote, all collaborators must re-clone). Overkill if audit shows only shell variable references.
- **Effort:** Medium
- **Risk:** Medium (history rewrite)

## Recommended Action

Solution A. Audit first, escalate to Solution B only if raw credentials are found in history.

## Technical Details

- **Affected files:** `.gitignore`, `.kamal/secrets`
- **Commands:** `git rm --cached .kamal/secrets`, then `git log --all --follow -p -- .kamal/secrets`

## Acceptance Criteria

- [ ] `git ls-files .kamal/secrets` returns nothing (file is untracked)
- [ ] `git log --all --follow -p -- .kamal/secrets` reviewed — no raw credentials found
- [ ] If raw credentials found: `RAILS_MASTER_KEY` and `KAMAL_REGISTRY_PASSWORD` rotated
- [ ] `.kamal/secrets` present on disk but absent from `git status`

## Work Log

- 2026-03-06: Identified by security-sentinel during /ce:review of foundation phase changes
