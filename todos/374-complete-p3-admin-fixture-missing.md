---
status: complete
priority: p3
issue_id: 374
tags: [code-review, testing, fixtures]
dependencies: []
---

## Problem Statement

There is no admin user fixture in `users.yml`. Multiple test files work around this by calling `@admin.update_columns(admin: true)` in their setup blocks. A dedicated `admin_user` fixture would eliminate this repetition.

## Findings

Several admin-related test files manually promote a user to admin in their setup method using `update_columns(admin: true)`. This is repeated boilerplate that a proper fixture would eliminate. It also means admin tests depend on a non-admin fixture being modified at runtime, which is less clear than having an explicitly defined admin fixture.

## Proposed Solutions

- Add an `admin_user` fixture to `test/fixtures/users.yml` with `admin: true` set directly.
- Update test files to reference the `admin_user` fixture instead of manually setting the admin flag.
- Remove `update_columns(admin: true)` calls from test setup blocks.

## Technical Details

**Affected files:** test/fixtures/users.yml, test/controllers/admin/dashboard_controller_test.rb, test/controllers/admin/users_controller_test.rb

## Acceptance Criteria

- [ ] `admin_user` fixture added to `test/fixtures/users.yml` with `admin: true`
- [ ] Test files reference the admin fixture directly
- [ ] All `update_columns(admin: true)` calls removed from test setup
- [ ] All admin controller tests pass with the new fixture
