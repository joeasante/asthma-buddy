---
status: complete
phase: 02-authentication
source: [02-01-SUMMARY.md, 02-02-SUMMARY.md, 02-03-SUMMARY.md]
started: 2026-03-06T00:00:00Z
updated: 2026-03-06T00:00:00Z
---

## Tests

### 1. Sign Up
expected: Fill in sign-up form (new email, 8+ char password, matching confirmation), submit → land on sign-in page with notice "Account created. Please check your email to verify your account."
result: pass

### 2. Unverified User Blocked from Login
expected: Before clicking the verification link, try to sign in with the account just created → redirected back to sign-in with "Please verify your email address before signing in. Check your inbox for a verification link."
result: pass

### 3. Email Verification Link
expected: Click the verification link from the email (in development, find it in Rails server logs or the letter_opener inbox) → redirected to sign-in page with a success notice. You can now log in.
result: pass

### 4. Sign In
expected: Enter verified email and password, click Sign in → land on home page. Nav shows your email address and a Sign out button.
result: pass

### 5. Nav Shows Correct State When Logged In
expected: After signing in, the top nav shows your email address and a Sign out button. No "Sign in" or "Sign up" links are visible.
result: pass

### 6. Sign Out
expected: Click Sign out → redirected to sign-in page. Nav now shows Sign in and Sign up links. Your email is gone from the nav.
result: pass

### 7. Nav Shows Correct State When Logged Out
expected: After signing out, the nav shows Sign in and Sign up links. No email, no Sign out button.
result: pass

### 8. Wrong Password Rejected
expected: On the sign-in form, enter a correct email but wrong password, click Sign in → redirected back to sign-in with "Try another email address or password."
result: pass

### 9. Session Persists Across Browser Close
expected: After logging in, close the browser tab and reopen the app at the same URL → you are still logged in (2-week persistent session cookie).
result: pass

### 10. Password Reset Request
expected: On the sign-in page, click "Forgot password?", enter your email address, click "Send reset link" → redirected to sign-in page with "Password reset instructions sent (if user with that email address exists)."
result: pass

### 11. Password Reset via Email Link
expected: Click the password reset link from the email (check server logs or letter_opener) → fill in new password and confirmation, click "Reset password" → see "Password has been reset." and can log in with the new password.
result: pass

## Summary

total: 11
passed: 11
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]
