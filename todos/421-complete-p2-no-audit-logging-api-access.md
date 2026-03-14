---
status: pending
priority: p2
issue_id: 421
tags: [code-review, security, compliance, api, hipaa]
dependencies: []
---

# No audit logging for API key lifecycle or API access

## Problem Statement

There is no logging of API key generation, revocation, or API endpoint access. For a health application handling PHI, audit trails are a HIPAA compliance requirement. Cannot detect unauthorized access or satisfy audit log requirements.

## Findings

- **Source**: security-sentinel (Finding #7)
- No log entries when API keys are generated or revoked
- No log entries when API endpoints are accessed (user ID, endpoint, timestamp, IP)

## Proposed Solutions

### Option A: Add logging to existing controller callbacks
- **Approach**: Log API key lifecycle in `Settings::ApiKeysController` and API access in `Api::V1::BaseController#authenticate_api_key!`
- **Effort**: Small
- **Risk**: Low

### Option B: Dedicated ApiAuditLog model
- **Approach**: Create a model to persist audit events with structured data
- **Effort**: Medium
- **Risk**: Low

## Acceptance Criteria

- [ ] API key generation logged with user ID, IP, timestamp
- [ ] API key revocation logged
- [ ] API endpoint access logged (user ID, endpoint, IP)

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from code review | HIPAA compliance gap |

## Resources

- PR #24: https://github.com/joeasante/asthma-buddy/pull/24
