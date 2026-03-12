---
status: pending
priority: p3
issue_id: 318
tags: [code-review, consistency, legal, internationalisation]
---

# 318 — P3 — Date format inconsistency across legal pages

## Problem Statement

The three legal pages use two different date formats for their "Last updated" date:

- `app/views/pages/privacy.html.erb` line 10: `Last updated: March 10, 2026` (US format — month name, day, year)
- `app/views/pages/terms.html.erb` line 10: `Last updated: March 10, 2026` (US format)
- `app/views/pages/cookie_policy.html.erb` line 10: `Last updated: 12 March 2026` (UK format — day month year)

Asthma Buddy is a UK-targeted application — its legal basis is UK GDPR, the Cookie Policy references UK PECR, and the Privacy Policy is described as covering data practices under UK law. The UK date format (`12 March 2026`, with the day first and no comma) is the appropriate convention. The `cookie_policy.html.erb` already uses the correct format; `privacy.html.erb` and `terms.html.erb` do not.

This inconsistency creates a jarring experience when users navigate between legal pages, and risks undermining the professional presentation of documents that are legally significant.

## Findings

- `app/views/pages/privacy.html.erb` line 10:
  ```erb
  <p class="legal-date">Last updated: March 10, 2026</p>
  ```

- `app/views/pages/terms.html.erb` line 10:
  ```erb
  <p class="legal-date">Last updated: March 10, 2026</p>
  ```

- `app/views/pages/cookie_policy.html.erb` line 10:
  ```erb
  <p class="legal-date">Last updated: 12 March 2026</p>
  ```

- The Privacy Policy references UK GDPR throughout and explicitly mentions "England and Wales" as the jurisdiction
- The Cookie Policy references UK PECR (Privacy and Electronic Communications Regulations) — UK-specific legislation
- UK date convention: `DD Month YYYY` (no comma, no ordinal suffix in formal documents)
- US date convention: `Month DD, YYYY` (comma after day, month first)
- The correct target format for all three pages is `12 March 2026` style (matching `cookie_policy.html.erb`)

**Affected files:**
- `app/views/pages/privacy.html.erb` line 10
- `app/views/pages/terms.html.erb` line 10

## Proposed Solutions

### Option A — Update privacy and terms to UK format (recommended)

Update the two non-conforming files to match the format already used in `cookie_policy.html.erb`:

- `privacy.html.erb` line 10: change `March 10, 2026` to `10 March 2026`
- `terms.html.erb` line 10: change `March 10, 2026` to `10 March 2026`

### Option B — Use a Rails date helper with locale

If the app ever introduces I18n locale configuration, the date could be rendered dynamically:

```erb
<p class="legal-date">Last updated: <%= l Date.new(2026, 3, 10), format: :long %></p>
```

With `en-GB` locale configured, `:long` format produces `10 March 2026`. This is future-state and not required for this ticket.

## Acceptance Criteria

- [ ] `privacy.html.erb` line 10 reads `Last updated: 10 March 2026`
- [ ] `terms.html.erb` line 10 reads `Last updated: 10 March 2026`
- [ ] `cookie_policy.html.erb` is unchanged (already uses the correct format)
- [ ] All three legal pages display the same date format when viewed in a browser
- [ ] No other US-format dates exist in the three legal view files

## Technical Details

| Field | Value |
|---|---|
| Affected files | `app/views/pages/privacy.html.erb` line 10; `app/views/pages/terms.html.erb` line 10 |
| Already correct | `app/views/pages/cookie_policy.html.erb` line 10 |
| Target format | `DD Month YYYY` — UK convention, e.g. `10 March 2026` |
| Current non-conforming format | `Month DD, YYYY` — US convention, e.g. `March 10, 2026` |
| Legal context | UK GDPR (Privacy), UK PECR (Cookie Policy), UK jurisdiction stated in Privacy Policy |
| User impact | Inconsistent date formatting noticed when navigating between legal pages |
| Severity | P3 — visual consistency / localisation |
| Fix complexity | Trivial — update two static strings |
