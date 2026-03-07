---
status: pending
priority: p1
issue_id: "002"
tags: [code-review, security, secrets, kamal, deployment]
dependencies: []
---

# `.kamal/secrets` Tracked in Git — Master Key Exposure Risk

## Problem Statement

`.kamal/secrets` is committed to the git repository and contains `RAILS_MASTER_KEY=$(cat config/master.key)`. This means every `kamal deploy` reads the master key from disk and injects it into the production container. For a health tracking app with future HIPAA considerations, the master key is the single decryption key for all Rails credentials (future SMTP passwords, API tokens, etc.). If `config/master.key` is ever accidentally committed, present in CI artifacts, or leaked from a runner, it will silently flow into the deployed container.

## Findings

**Flagged by:** security-sentinel (HIGH severity)

**Location:** `.kamal/secrets` (confirmed tracked: `git ls-files .kamal/secrets` returns the file)

```bash
# Current line in .kamal/secrets:
RAILS_MASTER_KEY=$(cat config/master.key)
```

The file itself contains no raw credentials, but its tracking in git means:
1. Future secret additions to this file are one commit away from exposure
2. The `$(cat config/master.key)` shell command creates a deploy-time dependency on the key file being present and correct on the deploying machine / CI runner
3. Kamal's own docs state: "DO NOT ENTER RAW CREDENTIALS HERE" — the spirit of this guidance requires the file not be tracked

## Proposed Solutions

### Option A — Gitignore + use environment variable (Recommended)
Add `/.kamal/secrets` to `.gitignore`. Source `RAILS_MASTER_KEY` from a CI/CD environment secret (GitHub Actions secret) instead of reading from a file.

```bash
# In CI workflow (set as GitHub Actions secret):
RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}

# In .kamal/secrets (not committed):
RAILS_MASTER_KEY=$RAILS_MASTER_KEY
```

**Pros:** Master key never touches the filesystem or git history at deploy time; standard CI secret management.
**Cons:** Requires adding the secret to GitHub Actions.
**Effort:** Small
**Risk:** Low

### Option B — 1Password integration (Kamal native)
Use the 1Password pattern commented in `.kamal/secrets`:
```bash
SECRETS=$(kamal secrets fetch --adapter 1password --account ... --from Vault/Item RAILS_MASTER_KEY)
RAILS_MASTER_KEY=$(kamal secrets extract RAILS_MASTER_KEY ${SECRETS})
```

**Pros:** Centralised credential management; audit trail.
**Cons:** Requires 1Password setup.
**Effort:** Medium
**Risk:** Low

### Option C — Keep file, rely on gitignore for master.key
Continue tracking `.kamal/secrets` but tighten `.gitignore` to ensure `config/master.key` can never be committed.

**Pros:** No change to deploy workflow.
**Cons:** Leaves the structural risk in place; does not address the CI artifact / runner scenario.
**Effort:** Minimal
**Risk:** Medium (accepted residual risk)

## Recommended Action

Option A — gitignore `.kamal/secrets` and use a GitHub Actions secret for `RAILS_MASTER_KEY`.

## Technical Details

**Affected files:**
- `.kamal/secrets`
- `.gitignore`
- `.github/workflows/ci.yml` — `RAILS_MASTER_KEY` currently commented out; uncomment when adding the GitHub secret

**Acceptance Criteria:**
- [ ] `/.kamal/secrets` added to `.gitignore`
- [ ] `.kamal/secrets` removed from git tracking (`git rm --cached .kamal/secrets`)
- [ ] `RAILS_MASTER_KEY` added as a GitHub Actions secret
- [ ] CI workflow references `secrets.RAILS_MASTER_KEY`
- [ ] `kamal deploy` still succeeds with the new secret source

## Work Log

- 2026-03-06: Identified by security-sentinel as HIGH severity in Foundation Phase review.

## Resources

- Kamal secrets documentation: https://kamal-deploy.org/docs/configuration/secrets/
