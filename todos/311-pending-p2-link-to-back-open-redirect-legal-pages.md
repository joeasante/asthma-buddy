---
status: pending
priority: p2
issue_id: 311
tags: [code-review, security, open-redirect]
---

# 311 — P2 — `link_to "← Back", :back` open redirect on legal pages

## Problem Statement

`link_to "← Back", :back` in three legal page views resolves the back URL from `request.env["HTTP_REFERER"]`, which is a value supplied entirely by the browser — and therefore fully attacker-controlled. A phishing page at `evil.com` can set the `Referer` header to itself, so any user who clicks a link to one of the app's legal pages from that phishing page will see a "← Back" link that points back to `evil.com`.

This is a classic open redirect via the Referer header. While the user must click the link (it does not redirect automatically), it is an effective phishing amplification vector: the redirect originates from a trusted domain (the app), lending it legitimacy.

The application already has a correct same-origin URL validation utility — `url_from` — used in the `Authentication` concern for the `return_to` parameter. The fix is a one-line change per view to use that same utility.

## Findings

- `app/views/pages/cookie_policy.html.erb` line 60: `link_to "← Back", :back, class: "legal-back-link"`
- `app/views/pages/privacy.html.erb` line 77: `link_to "← Back", :back, class: "legal-back-link"`
- `app/views/pages/terms.html.erb` line 50: `link_to "← Back", :back, class: "legal-back-link"`
- In Rails, `:back` resolves to `request.env["HTTP_REFERER"]` — the raw `Referer` request header
- The `Referer` header is set by the browser from the page that linked to the current URL; it is not validated by Rails
- An external site linking to any of these pages can set `Referer: https://evil.com/phishing`; the Back link then points off-site
- `url_from` (available in `ActionController::Base` as of Rails 7.1) returns `nil` for URLs whose origin does not match the current request origin — providing safe same-origin validation
- The `Authentication` concern already calls `url_from(params[:return_to])` to guard the post-login redirect, demonstrating existing awareness of the pattern

**Affected files:**
- `app/views/pages/cookie_policy.html.erb` (line 60)
- `app/views/pages/privacy.html.erb` (line 77)
- `app/views/pages/terms.html.erb` (line 50)

## Proposed Solutions

### Option A — Replace `:back` with `url_from` + `root_path` fallback (recommended)

```erb
<%= link_to "← Back", url_from(request.referer) || root_path, class: "legal-back-link" %>
```

`url_from` validates that the URL shares the same origin as the current request. If the Referer is absent, external, or malformed it returns `nil`; the `|| root_path` fallback ensures the link always points somewhere safe. This is a surgical, zero-regression change — the behaviour for legitimate internal navigation is identical to the current code.

### Option B — Hard-code a safe back destination

Remove the dynamic back link entirely and replace it with a fixed link to a known safe destination (e.g. `root_path`, or `settings_path` if the legal pages are most often accessed from settings):

```erb
<%= link_to "← Back", root_path, class: "legal-back-link" %>
```

Eliminates the Referer dependency entirely. Slightly worse UX (the back destination is always the same regardless of where the user came from), but completely eliminates the redirect risk.

### Option C — Restrict to known internal referrers

Build an allowlist of internal paths (e.g. `/`, `/settings`, `/dashboard`) and fall back to `root_path` if the Referer does not match. More granular than option A but also more fragile — the allowlist must be maintained as routes change. Option A already covers this case more robustly via origin matching.

## Acceptance Criteria

- [ ] None of the three legal page views use `link_to "← Back", :back`
- [ ] The Back link always resolves to a same-origin URL or a safe fallback (`root_path`)
- [ ] A Referer header pointing to an external domain does NOT produce an off-site link
- [ ] A missing Referer header produces a link to `root_path` (no broken/blank href)
- [ ] The Back link continues to navigate to the correct previous page when accessed normally from within the app
- [ ] Test coverage added or updated to assert the Back link does not resolve to external URLs

## Technical Details

| Field | Value |
|---|---|
| Affected files | `app/views/pages/cookie_policy.html.erb:60`, `privacy.html.erb:77`, `terms.html.erb:50` |
| Root cause | `link_to :back` uses `HTTP_REFERER` without origin validation |
| Attack vector | External phishing page sets `Referer` to itself; Back link points off-site |
| Severity | P2 — requires user interaction (clicking the link), but exploitable via social engineering |
| Existing mitigation available | `url_from` already used in `Authentication` concern for `return_to` param |
| Rails version note | `url_from` available since Rails 7.1; confirmed present in Rails 8.1.2 |
