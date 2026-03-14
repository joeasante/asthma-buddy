# Phase 27: Multi-Factor Authentication - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

TOTP-based two-factor authentication: setup via QR code, mandatory TOTP entry at login (pending MFA session state), 10 one-time recovery codes, ability to disable MFA. TOTP secrets and recovery codes encrypted at rest.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
- MFA setup location (dedicated security page vs section in account settings)
- Login challenge screen design and layout
- Recovery codes presentation (dedicated page vs modal, download UX)
- QR code styling and presentation
- Recovery code regeneration flow

### Locked from Prior Decisions (STATE.md)
- Use `rotp` gem for TOTP generation/verification
- Use `rqrcode` gem for QR code generation
- MFA must use "pending" session state — don't authenticate before TOTP verification
- TOTP secrets encrypted via Rails Active Record Encryption

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches. User deferred all UX decisions to Claude's discretion.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 27-multi-factor-authentication*
*Context gathered: 2026-03-14*
