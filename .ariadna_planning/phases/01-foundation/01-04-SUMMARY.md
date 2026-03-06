---
phase: 01-foundation
plan: 04
subsystem: infra
tags: [kamal, ci, github-actions, deploy, docker]

requires:
  - phase: 01-foundation plan 01-03
    provides: green test baseline — CI runs bin/rails test

provides:
  - CI pipeline with corrected actions/checkout@v4 (was broken v6)
  - .kamal/secrets with KAMAL_REGISTRY_PASSWORD ready for deploy
  - Staging deploy deferred — config/deploy.yml retains placeholders

affects: [deploy phase, any future phase requiring CI green]

tech-stack:
  added: []
  patterns: [GitHub Actions CI — scan_ruby, scan_js, lint, test, system-test jobs]

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - .kamal/secrets

key-decisions:
  - "Staging deploy deferred (option C) — server not provisioned yet"
  - "actions/checkout@v6 → @v4 (v6 does not exist; v4 is latest stable)"
  - "KAMAL_REGISTRY_PASSWORD uncommented in .kamal/secrets — ready when registry chosen"

patterns-established:
  - "CI runs 5 jobs: scan_ruby (Brakeman), scan_js (importmap audit), lint (RuboCop), test, system-test"

requirements_covered: []

duration: 5min
completed: 2026-03-06
---

# Plan 01-04: CI Pipeline + Kamal Config Summary

**CI pipeline corrected (actions/checkout@v4) and Kamal secrets template activated — staging deploy deferred until server provisioned**

## Performance

- **Duration:** ~5 min
- **Completed:** 2026-03-06
- **Tasks:** 1 of 3 (tasks 2 and 3 deferred — require staging server)
- **Files modified:** 2

## Accomplishments
- Fixed `actions/checkout@v6` → `@v4` across all 5 CI jobs (v6 does not exist; pipeline was broken)
- Activated `KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD` in `.kamal/secrets`
- CI pipeline structure confirmed: scan_ruby, scan_js, lint, test, system-test jobs all present

## Task Commits

1. **Task 1: CI fix + secrets template** — `30101c4` (feat)

## Files Created/Modified
- `.github/workflows/ci.yml` — updated 5 `checkout@v6` → `checkout@v4` references
- `.kamal/secrets` — uncommented `KAMAL_REGISTRY_PASSWORD` ENV pull

## Decisions Made
- User chose **Option C** (skip staging deploy for now). `config/deploy.yml` retains `192.168.0.1` and `localhost:5555` placeholders until a VPS is provisioned.
- Tasks 2 and 3 (Kamal setup + staging verification) are deferred — not blocking Phase 2.

## Deviations from Plan
None from what was executed. Tasks 2–3 explicitly deferred per user decision.

## Issues Encountered
- `actions/checkout@v6` used throughout CI — this version doesn't exist. Fixed to `@v4` (current stable).

## User Setup Required

When ready to deploy to staging:
1. Provision a VPS (Hetzner CX21 recommended — ~€5/mo, Ubuntu 22.04)
2. Choose a Docker registry (Docker Hub or ghcr.io)
3. Update `config/deploy.yml`:
   - Replace `192.168.0.1` with real server IP
   - Replace `localhost:5555` with registry server
   - Set `image:` to `username/asthma-buddy`
   - Uncomment `username:` and `password: [KAMAL_REGISTRY_PASSWORD]` under `registry:`
4. Set `KAMAL_REGISTRY_PASSWORD` in shell ENV
5. Run `bin/kamal setup`
6. Verify: `curl http://SERVER_IP/up` returns 200

## Next Phase Readiness
- CI pipeline is functional. Push to `main` will run all 5 jobs.
- Phase 2 (authentication) can proceed immediately — staging deploy is not a blocker.

---
*Phase: 01-foundation*
*Completed: 2026-03-06*
