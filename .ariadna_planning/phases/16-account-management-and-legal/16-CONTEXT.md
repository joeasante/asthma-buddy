# Phase 16 Context

## Decisions

**Account Deletion UI placement:** Add a "Danger Zone" section to the existing `settings/show` page (SettingsController). Do not create a new account settings page. The deletion form lives at the bottom of the existing settings page.

**Account Deletion route:** Use `DELETE /account` with a new `AccountsController#destroy`. The settings page hosts the form; the controller handles the destruction.

**Legal page content:** Generate placeholder UK GDPR-compliant text for both `/terms` and `/privacy`. Content should be reasonable and replace-ready before public launch.

**Cookie notice style:** Minimal fixed bottom bar — unobtrusive strip at the bottom of the viewport, dismissible with an X button, no JavaScript cookie library. State stored in `session[:cookie_notice_shown]`.

## Claude's Discretion

- Footer link placement and styling
- Exact wording of the cookie notice text
- Danger Zone section visual styling (red/destructive styling expected)
- Legal page layout (simple prose, no special structure required)

## Deferred Ideas

- Full cookie consent management (per-category consent, GDPR consent log)
- Account export/download-my-data
- Account deactivation (soft delete) vs permanent deletion
