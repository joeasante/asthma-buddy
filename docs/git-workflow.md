# Git Workflow — Asthma Buddy

## Branch Structure

```
main   → production (always deployable, always clean)
dev    → integration (all in-progress work lives here)
feature/*  → individual changes (short-lived, branch off dev)
hotfix/*   → emergency production fixes (branch off main)
```

---

## Everyday Development

### 1. Start a new piece of work

```bash
git checkout dev
git pull                          # sync with remote first
git checkout -b feature/my-thing  # create feature branch
```

### 2. Work and commit

```bash
# ... make changes ...
git add .
git commit -m "feat: describe what you did"
```

Use short prefixes to keep history readable:
- `feat:` — new feature
- `fix:` — bug fix
- `refactor:` — restructure without behaviour change
- `test:` — tests only
- `chore:` — maintenance (deps, config, etc.)
- `wip:` — work in progress (use sparingly)

### 3. Merge finished work into dev

```bash
git checkout dev
git merge --no-ff feature/my-thing  # --no-ff keeps a merge commit in history
git push origin dev
git branch -d feature/my-thing      # clean up
```

### 4. Deploy to production

Only when dev is stable and tested.

```bash
git checkout main
git merge --no-ff dev
git push origin main
git tag -a v1.x.x -m "Release v1.x.x"  # optional but useful
git push origin --tags
kamal deploy
```

---

## Hotfix (urgent production fix)

Use this when main needs a fix but dev has in-progress work you're not ready to ship.

```bash
# 1. Branch off main (not dev)
git checkout main
git checkout -b hotfix/describe-the-fix

# 2. Fix, commit
git add .
git commit -m "fix: describe the fix"

# 3. Merge into main and deploy
git checkout main
git merge --no-ff hotfix/describe-the-fix
git push origin main
kamal deploy

# 4. Backport into dev so the fix isn't lost
git checkout dev
git merge --no-ff hotfix/describe-the-fix
git push origin dev

# 5. Clean up
git branch -d hotfix/describe-the-fix
```

---

## Automation — Git Aliases

Add these to `~/.gitconfig` under `[alias]` to reduce typing:

```ini
[alias]
  # Start a new feature branch from dev
  feature = "!f() { git checkout dev && git pull && git checkout -b feature/$1; }; f"

  # Finish a feature: merge into dev, push, delete branch
  done    = "!f() { BRANCH=$(git branch --show-current) && git checkout dev && git merge --no-ff $BRANCH && git push origin dev && git branch -d $BRANCH; }; f"

  # Ship dev to production
  ship    = "!git checkout main && git merge --no-ff dev && git push origin main && git checkout dev"

  # Start a hotfix from main
  hotfix  = "!f() { git checkout main && git pull && git checkout -b hotfix/$1; }; f"

  # Finish a hotfix: merge to main + dev, push both, delete branch
  hotdone = "!f() { BRANCH=$(git branch --show-current) && git checkout main && git merge --no-ff $BRANCH && git push origin main && git checkout dev && git merge --no-ff $BRANCH && git push origin dev && git branch -d $BRANCH; }; f"
```

### Usage after adding aliases

```bash
git feature peak-flow-export    # creates feature/peak-flow-export off dev
git done                        # merges current branch into dev and cleans up
git ship                        # merges dev → main and pushes (run kamal deploy after)
git hotfix broken-query         # creates hotfix/broken-query off main
git hotdone                     # merges hotfix into both main and dev
```

### Install the aliases now

Run this once in your terminal:

```bash
git config --global alias.feature '!f() { git checkout dev && git pull && git checkout -b feature/$1; }; f'
git config --global alias.done    '!f() { BRANCH=$(git branch --show-current) && git checkout dev && git merge --no-ff $BRANCH && git push origin dev && git branch -d $BRANCH; }; f'
git config --global alias.ship    '!git checkout main && git merge --no-ff dev && git push origin main && git checkout dev'
git config --global alias.hotfix  '!f() { git checkout main && git pull && git checkout -b hotfix/$1; }; f'
git config --global alias.hotdone '!f() { BRANCH=$(git branch --show-current) && git checkout main && git merge --no-ff $BRANCH && git push origin main && git checkout dev && git merge --no-ff $BRANCH && git push origin dev && git branch -d $BRANCH; }; f'
```

---

## Quick Reference

| What you want to do         | Command                          |
|-----------------------------|----------------------------------|
| Start new feature           | `git feature <name>`             |
| Finish feature → dev        | `git done`                       |
| Deploy dev → production     | `git ship` then `kamal deploy`   |
| Start urgent hotfix         | `git hotfix <name>`              |
| Finish hotfix → main + dev  | `git hotdone` then `kamal deploy`|
| Check what branch you're on | `git branch --show-current`      |
| See recent history          | `git log --oneline --graph`      |
