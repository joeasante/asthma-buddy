---
status: complete
phase: 20-legal-pages-cookie-banner-error-pages
source: [20-01-SUMMARY.md, 20-02-SUMMARY.md, 20-03-SUMMARY.md]
started: 2026-03-12T18:45:00Z
updated: 2026-03-12T18:45:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cookie Policy page accessible without login
expected: Visit /cookies while logged out. Page loads (no redirect to login). Shows "Cookie Policy" heading, lists two cookies (_asthma_buddy_session and cookie_notice_dismissed), includes a section on PECR rights, and references the ICO.
result: pass

### 2. Legal pages narrow layout
expected: Visit /terms, /privacy, and /cookies. All three pages render in a narrow column (roughly 680px wide), clearly narrower than the standard page width. The content doesn't stretch full-width.
result: pass

### 3. Footer Cookies link
expected: On any page (logged in or out), the page footer contains a "Cookies" link alongside the existing Privacy and Terms links.
result: pass

### 4. Cookie banner first visit
expected: Open the app in a browser where you've never visited before (or clear cookies). A cookie notice banner appears at the bottom of the page before you've dismissed it.
result: pass

### 5. Cookie banner persistent dismissal
expected: Dismiss the cookie notice banner (click the dismiss/accept button). Then close the browser tab completely and reopen the app. The banner should NOT reappear — even after closing and reopening the browser.
result: pass

### 6. Branded 404 page
expected: Visit a URL that doesn't exist (e.g. /this-does-not-exist). Instead of a plain Rails error page, you see a styled Asthma Buddy 404 page with a large "404" number, a short message, and a link back to the dashboard or home page.
result: pass

### 7. Branded 500 page
expected: Visit /500 directly. You see a styled Asthma Buddy error page with a large "500" number, a message about the server error, and a support/home link. The page matches the app's visual design.
result: pass

### 8. Maintenance page standalone
expected: Open public/maintenance.html directly in your browser as a file (File → Open, or drag it into the browser). It renders correctly showing "Asthma Buddy" and a maintenance message — no broken styles, no missing content.
result: skipped

## Summary

total: 8
passed: 7
issues: 0
pending: 0
skipped: 1

## Gaps

[none yet]
