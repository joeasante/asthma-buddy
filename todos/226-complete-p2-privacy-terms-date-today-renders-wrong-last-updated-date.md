---
status: pending
priority: p2
issue_id: "226"
tags: [legal, gdpr, code-review, rails]
dependencies: []
---

# `Date.today` in terms.html.erb and privacy.html.erb Renders Today's Date Instead of Last-Modified Date

## Problem Statement

Both legal pages use `<%= Date.today.strftime("%B %-d, %Y") %>` for the "Last updated" field. This renders the current visit date, not the date the content was last edited.

The "Last updated" date on a legal document is a statement of fact about when the content changed — it has legal significance for GDPR compliance. Users must be notified of material changes, and the document must accurately record when those changes occurred. If the page renders "March 15, 2026" on March 15 and "March 20, 2026" on March 20 without the content changing, the date is inaccurate and the legal record is falsified on every request.

## Findings

**Flagged by:** architecture-strategist

**Locations:**
- `app/views/pages/privacy.html.erb` line 8: `<%= Date.today.strftime("%B %-d, %Y") %>`
- `app/views/pages/terms.html.erb` line 8: `<%= Date.today.strftime("%B %-d, %Y") %>`

**Observed behaviour:** Both pages display the server date at render time, not the content revision date. The date changes daily without any content change.

## Proposed Solutions

### Option A — Hardcoded String Literal (Recommended)

Replace `<%= Date.today.strftime("%B %-d, %Y") %>` with a hardcoded string literal:

```erb
March 10, 2026
```

Update this literal manually on each legal revision. Simple, honest, zero moving parts.

**Pros:** Trivially correct; no code path needed; accurate legal record.
**Cons:** Developer must remember to update the string on each legal revision.
**Effort:** Trivial
**Risk:** None

### Option B — Controller Constant

Define a constant in `PagesController`:

```ruby
PRIVACY_LAST_UPDATED = "March 10, 2026"
TERMS_LAST_UPDATED   = "March 10, 2026"
```

Reference via `PagesController::PRIVACY_LAST_UPDATED` in the view (or assign to `@privacy_last_updated` in the action).

**Pros:** Slightly more traceable — one place per document to update; easier to grep.
**Cons:** More indirection for the same manual-update requirement; constants across both documents require two updates.
**Effort:** Small
**Risk:** None

## Recommended Action

Option A. The simplest fix for a legal document date is a literal string. Any developer editing the legal content will see the hardcoded date and know to update it. The actual content revision date for Phase 16 is 2026-03-10.

## Technical Details

**Affected files:**
- `app/views/pages/privacy.html.erb`
- `app/views/pages/terms.html.erb`

**Acceptance Criteria:**
- [ ] Both pages display a hardcoded "Last updated" date matching when content was last revised
- [ ] No `Date.today` or dynamic date computation in either legal page view
- [ ] Date reflects the actual Phase 16 content creation date (2026-03-10)

## Work Log

- 2026-03-10: Identified by architecture-strategist in Phase 16 code review.

## Resources

- GDPR Article 13/14 — information to be provided at time of collection
- GDPR Article 7 — conditions for consent and record of when terms were accepted
