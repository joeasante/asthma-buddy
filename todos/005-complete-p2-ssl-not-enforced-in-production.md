---
status: pending
priority: p2
issue_id: "005"
tags: [code-review, security, ssl, production, hipaa]
dependencies: []
---

# SSL Enforcement Disabled in Production

## Problem Statement

`config/environments/production.rb` has `config.assume_ssl = true` and `config.force_ssl = true` commented out. Without these, the app serves over plain HTTP in production. Session cookies are transmitted without the `Secure` flag. CSRF tokens travel in plaintext. Future health data (symptom logs, peak flow readings) will be sent unencrypted. This is a HIPAA compliance gap — unencrypted transport of PHI is not permissible.

## Findings

**Flagged by:** security-sentinel (MEDIUM), architecture-strategist (MEDIUM)

**Location:** `config/environments/production.rb` lines 28–34

```ruby
# config.assume_ssl = true
# config.force_ssl = true
```

Thruster (the Kamal HTTP proxy) can terminate TLS, but defense-in-depth requires `force_ssl` at the Rails layer as well. Thruster terminating TLS and passing plain HTTP to Puma is common, which is why `assume_ssl: true` is needed alongside `force_ssl: true`.

The Kamal `proxy.ssl` option in `config/deploy.yml` is also currently commented out.

## Proposed Solutions

### Option A — Uncomment both production settings + activate Kamal proxy SSL
```ruby
# config/environments/production.rb
config.assume_ssl = true
config.force_ssl = true
```

```yaml
# config/deploy.yml proxy section — uncomment ssl block
proxy:
  ssl: true
  host: your-domain.com
```

**Pros:** Full defense-in-depth; HIPAA path compliant.
**Cons:** Requires a valid TLS certificate and the actual domain to be configured in Kamal.
**Effort:** Small (configuration change)
**Risk:** Low — must be done before any user data is handled

### Option B — Enable Rails SSL settings without Kamal proxy SSL
Set `assume_ssl` and `force_ssl` in Rails; leave Kamal proxy SSL for when the VPS is provisioned.

**Pros:** Rails-level protection immediately; proxy SSL follows later.
**Cons:** If Kamal proxy is not doing TLS, `force_ssl` will cause redirect loops.
**Effort:** Small
**Risk:** Medium — test deployment behavior first

## Recommended Action

Option A — configure together when the VPS hostname is known. Block Phase 2 deployment on this.

## Technical Details

**Affected files:**
- `config/environments/production.rb`
- `config/deploy.yml`

**Acceptance Criteria:**
- [ ] `config.assume_ssl = true` uncommented
- [ ] `config.force_ssl = true` uncommented
- [ ] Kamal proxy `ssl: true` enabled with correct hostname
- [ ] HTTP requests redirect to HTTPS in production
- [ ] Session cookies have `Secure` flag set

## Work Log

- 2026-03-06: Identified by security-sentinel in Foundation Phase review. Must resolve before Phase 2 production deployment.
