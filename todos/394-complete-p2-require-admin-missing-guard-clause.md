---
status: complete
priority: p2
issue_id: "394"
tags: [code-review, security, architecture]
dependencies: []
---

## Problem Statement
`Admin::BaseController#require_admin` doesn't halt the filter chain when the user is not an admin. It calls `redirect_to` inside `respond_to` but doesn't return or use `throw :abort`, so the controller action still executes after the redirect is queued. In practice Rails won't render twice, but the action body runs (potentially loading/modifying data) before the redirect completes.

## Findings
In `app/controllers/admin/base_controller.rb`, the `require_admin` method:
```ruby
def require_admin
  unless Current.user&.admin?
    respond_to do |format|
      format.html { redirect_to main_app.root_path, alert: "..." }
      format.json { render json: { error: "Forbidden" }, status: :forbidden }
    end
  end
end
```
The `unless` block doesn't use `and return` or a guard clause pattern, so execution continues into the action.

## Proposed Solutions
### Option A: Add `and return` (Recommended)
```ruby
def require_admin
  return if Current.user&.admin?
  Rails.logger.warn "..."
  respond_to do |format|
    format.html { redirect_to main_app.root_path, alert: "..." }
    format.json { render json: { error: "Forbidden" }, status: :forbidden }
  end
end
```
Using guard clause pattern ensures the before_action halts. Rails automatically halts the chain when `redirect_to` or `render` is called in a before_action, but the guard clause makes intent explicit and prevents any code after the `unless` block from running.

**Pros:** Clearer intent, standard Rails pattern.
**Effort:** Small.
**Risk:** None.

## Acceptance Criteria
- [ ] `require_admin` uses guard clause pattern
- [ ] Non-admin access to `/jobs` redirects without executing action
- [ ] All tests pass
