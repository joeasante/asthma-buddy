---
status: pending
priority: p3
issue_id: "029"
tags: [code-review, security, git, housekeeping]
dependencies: []
---

# `.DS_Store` Files Committed to Repository — Information Disclosure + Repo Noise

## Problem Statement

Four `.DS_Store` files are tracked in the git repository. These macOS metadata files reveal internal directory structure (subfolder names, icon positions, file listings) beyond what the code itself shows, and are a minor information disclosure for a health application. They also create perpetual noise in `git status` on macOS development machines.

## Findings

**Flagged by:** security-sentinel (F-08)

**Tracked files:**
```
.DS_Store
app/.DS_Store
config/.DS_Store
test/.DS_Store
```

`.gitignore` currently does not have an entry for `.DS_Store`.

## Proposed Solutions

### Solution A: Remove from tracking and add to .gitignore (Recommended)

```bash
# Remove from git tracking (keeps files on disk)
git rm --cached .DS_Store app/.DS_Store config/.DS_Store test/.DS_Store

# Add to .gitignore
echo "**/.DS_Store" >> .gitignore

# Commit
git add .gitignore
git commit -m "chore: untrack .DS_Store files and add to .gitignore"
```

Also recommend adding to global gitignore on developer machines:
```bash
echo "**/.DS_Store" >> ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global
```
- **Effort:** Small
- **Risk:** None

## Recommended Action

Solution A. Standard housekeeping that should have been in the initial repo setup.

## Technical Details

- **Files to remove from tracking:** `.DS_Store`, `app/.DS_Store`, `config/.DS_Store`, `test/.DS_Store`
- **Addition to .gitignore:** `**/.DS_Store`

## Acceptance Criteria

- [ ] `git ls-files | grep DS_Store` returns nothing
- [ ] `.gitignore` contains `**/.DS_Store`
- [ ] `.DS_Store` files still exist on disk (not deleted)
- [ ] No `.DS_Store` appears in `git status` after the commit

## Work Log

- 2026-03-06: Identified by security-sentinel during /ce:review of foundation phase changes
