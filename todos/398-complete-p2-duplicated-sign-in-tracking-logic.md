---
status: pending
priority: p2
issue_id: 398
tags: [code-review, architecture, dry, mfa]
dependencies: []
---

# Duplicated sign-in tracking logic across two controllers

## Problem Statement

The login completion logic (start_new_session_for, last_seen_at, last_sign_in_at, sign_in_count increment) is duplicated identically between `SessionsController#create` (lines 54-57) and `MfaChallengeController#complete_mfa_login` (lines 73-76). If a third auth path is added (Phase 28 API), this must be copied again. Changes to tracking logic must be synchronized across all locations.

## Findings

- **Source:** kieran-rails-reviewer, architecture-strategist, simplicity-reviewer, pattern-recognition, performance-oracle (all 5 flagged this)
- **Files:** `app/controllers/sessions_controller.rb:54-57`, `app/controllers/mfa_challenge_controller.rb:70-76`
- **Performance note:** The two UPDATE statements (update_columns + update_all) can also be consolidated into a single SQL UPDATE.

## Proposed Solutions

### Option A: Extract to Authentication concern (Recommended)
Add `complete_sign_in(user)` method to `app/controllers/concerns/authentication.rb`. Both controllers call it.
- **Pros:** Single source of truth, both controllers already include the concern
- **Cons:** None
- **Effort:** Small (10 min)
- **Risk:** None

### Option B: Extract to User model method
Add `User#record_sign_in!` that handles last_sign_in_at and sign_in_count.
- **Pros:** Keeps tracking logic on the model
- **Cons:** Session-related logic (start_new_session_for, last_seen_at) would stay in controllers
- **Effort:** Small
- **Risk:** None

## Recommended Action

Option A — extract `complete_sign_in(user)` to the Authentication concern. Also consolidate the two UPDATE statements into one.

## Acceptance Criteria

- [ ] Single `complete_sign_in` method in Authentication concern
- [ ] SessionsController and MfaChallengeController both call it
- [ ] Only one UPDATE statement per login (not two)
- [ ] All existing tests pass

## Work Log

| Date | Action | Learnings |
|------|--------|-----------|
| 2026-03-14 | Created from Phase 27 code review | 5 of 7 review agents flagged this independently |
