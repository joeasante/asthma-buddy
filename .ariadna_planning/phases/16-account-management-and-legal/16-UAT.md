---
status: complete
phase: 16-account-management-and-legal
source: 16-01-SUMMARY.md, 16-02-SUMMARY.md, 16-03-SUMMARY.md
started: 2026-03-10T00:00:00Z
updated: 2026-03-10T00:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cookie Notice Appears on First Visit
expected: A fixed banner at the bottom of the page is visible on first page load (or after signing out and back in). It mentions cookies/session and has a dismiss or "Got it" button.
result: pass

### 2. Cookie Notice Dismisses with Animation
expected: Clicking the dismiss button causes the banner to slide/fade out and disappear. After dismissal, the banner is gone for the rest of the session (does not reappear on navigation).
result: pass

### 3. Terms of Service Page
expected: Visiting /terms shows a full Terms of Service page with multiple sections (About, Eligibility, Health Data Disclaimer, Governing Law, etc.). Content is substantive, not just a stub.
result: pass

### 4. Privacy Policy Page
expected: Visiting /privacy shows a full Privacy Policy with sections covering what data is collected, lawful basis, your rights, and how to contact ICO. Content is substantive.
result: pass

### 5. Footer Links to Legal Pages
expected: The footer on both authenticated and unauthenticated pages has links to Terms and Privacy Policy.
result: pass

### 6. Settings Page Shows Danger Zone
expected: Visiting Settings shows a "Danger Zone" section at the bottom with a heading like "Delete Account" and a form requiring you to type "DELETE" to confirm.
result: pass

### 7. Wrong Confirmation Does Not Delete Account
expected: Type anything other than "DELETE" (e.g. "delete" or "yes") in the confirmation field and submit. You should stay on the Settings page with an error message. Your account is intact.
result: pass

### 8. Correct Confirmation Deletes Account
expected: Type "DELETE" exactly and submit. You should be redirected to the home/login page with a success notice. Signing in with the deleted credentials should fail.
result: pass

## Summary

total: 8
passed: 8
issues: 0
pending: 0
skipped: 0

## Gaps

