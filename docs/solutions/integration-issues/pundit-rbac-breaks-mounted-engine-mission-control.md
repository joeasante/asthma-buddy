---
title: "Mission Control Jobs dashboard broken after RBAC/Pundit implementation"
date: 2026-03-14
category: integration-issues
tags:
  - pundit
  - rbac
  - mission-control
  - rails-engines
  - routing
  - main_app
components:
  - app/controllers/concerns/authentication.rb
  - app/controllers/admin/base_controller.rb
  - app/controllers/application_controller.rb
  - config/initializers/mission_control.rb
severity: high
symptoms:
  - "No route matches {action: \"new\", controller: \"sessions\", server_id: nil}"
  - "Pundit::AuthorizationNotPerformedError on Mission Control engine controllers"
  - "/jobs dashboard returns 500 after Pundit RBAC deploy"
root_cause: >
  Two issues introduced by RBAC/Pundit integration:
  (1) Authentication concern used bare route helpers (new_session_path, root_url)
  which resolved against the mounted engine's routes instead of the main app.
  (2) Pundit's verify_authorized after_action fired on engine controllers that
  never call authorize.
resolution: >
  (1) Prefixed route helpers with main_app. in the Authentication concern.
  (2) Added skip_pundit to Admin::BaseController so engine controllers bypass
  verify_authorized.
related_issues: []
---

# Mission Control Jobs Broken After Pundit RBAC

## Symptoms

After deploying Phase 26 (RBAC with Pundit authorization), visiting `/jobs` (Mission Control Jobs dashboard) produced two sequential 500 errors:

1. **Unauthenticated visit:** `No route matches {action: "new", controller: "sessions", server_id: nil}`
2. **Authenticated admin visit:** `Pundit::AuthorizationNotPerformedError`

## Root Cause

### Error 1 — Route helper resolution inside a mounted engine

The `Authentication` concern's `request_authentication` method used bare route helpers:

```ruby
# BROKEN — resolves against the engine's routes, not the main app
redirect_to new_session_path
session[:return_to_after_authenticating] = url_from(request.url) || root_url
```

When a request is handled inside a mounted engine (Mission Control Jobs at `/jobs`), Rails resolves route helpers against the **engine's** route set. Mission Control defines routes with a `server_id` segment, so `new_session_path` tried to generate `/jobs/servers//sessions/new` and failed because `server_id` was nil.

### Error 2 — Pundit callback leaking into engine controllers

`ApplicationController` declares `after_action :verify_authorized` as a deny-by-default safety net. Mission Control's engine controllers inherit from `Admin::BaseController < ApplicationController`, picking up this callback. But engine controllers are third-party code that never calls `authorize`, so `verify_authorized` raises every time.

**Inheritance chain:** `MissionControl::Jobs::ApplicationController < Admin::BaseController < ApplicationController`

This was configured in `config/initializers/mission_control.rb`:
```ruby
MissionControl::Jobs.base_controller_class = "Admin::BaseController"
```

## Solution

### Fix 1 — Prefix route helpers with `main_app.`

In `app/controllers/concerns/authentication.rb`:

```ruby
def request_authentication
  respond_to do |format|
    format.html do
      session[:return_to_after_authenticating] = url_from(request.url) || main_app.root_url
      redirect_to main_app.new_session_path
    end
    format.json { render json: { error: "Authentication required" }, status: :unauthorized }
  end
end

def after_authentication_url
  session.delete(:return_to_after_authenticating) || main_app.root_url
end
```

In `app/controllers/admin/base_controller.rb`:

```ruby
redirect_to main_app.root_path, alert: "You do not have access to that page."
```

### Fix 2 — Skip Pundit verification for engine controllers

In `app/controllers/admin/base_controller.rb`:

```ruby
class Admin::BaseController < ApplicationController
  skip_pundit  # Mounted engines (Mission Control) inherit this; they never call authorize

  before_action :require_admin
  # ...
end
```

The app's own admin controllers (`Admin::DashboardController`, `Admin::UsersController`, `Admin::SiteSettingsController`) still call `authorize` explicitly in every action, so authorization remains enforced.

## Why This Works

**`main_app` proxy:** Rails provides `main_app` as an explicit reference to the host application's route set. Inside a mounted engine, bare helpers like `root_path` resolve against the engine. `main_app.root_path` forces resolution against the host app's `config/routes.rb`.

**`skip_pundit`:** Skips the `verify_authorized` after_action callback. Engine controllers that never call `authorize` won't trigger the safety net. First-party admin controllers still call `authorize` directly, so deny-by-default is preserved for code we control.

## Verification

1. Visit `/jobs` while logged out — redirects to `/session/new` (not a 500)
2. Visit `/jobs` as admin — Mission Control dashboard renders
3. Visit `/jobs` as non-admin — redirects to root with "access denied" flash
4. `bin/rails test` — all 623 tests pass

## Prevention Checklist

When adding global callbacks (`before_action`/`after_action`) to `ApplicationController`:

- [ ] **Audit all mounted engines.** Check `config/routes.rb` for `mount` statements. Every mounted engine may inherit from your base controller.
- [ ] **Grep for bare route helpers in concerns:** `grep -rn '_path\|_url' app/controllers/concerns/ | grep -v 'main_app\.'`
- [ ] **Add integration tests for mounted engine paths** — a simple `get "/jobs"` in a test would have caught both errors.
- [ ] **Ask: "What happens when this fires on a controller I didn't write?"** If it calls methods the foreign controller doesn't define, add a guard clause.

## Test Cases

```ruby
# test/integration/mounted_engines_test.rb
class MountedEnginesTest < ActionDispatch::IntegrationTest
  test "mission control jobs dashboard is accessible by admin" do
    sign_in users(:admin)
    get "/jobs"
    assert_response :success
  end

  test "mission control jobs redirects unauthenticated users to sign in" do
    get "/jobs"
    assert_redirected_to new_session_path
  end

  test "mission control jobs denies non-admin users" do
    sign_in users(:member)
    get "/jobs"
    assert_redirected_to root_path
  end
end
```

## Related Files

- `config/initializers/mission_control.rb` — sets `Admin::BaseController` as engine base
- `config/routes.rb:89` — `mount MissionControl::Jobs::Engine, at: "/jobs"`
- `app/controllers/application_controller.rb` — defines `skip_pundit` mechanism
- `todos/380-complete-p2-skip-pundit-inheritance-inversion.md` — related skip_pundit inheritance concern

## Key Takeaway

**Always use `main_app.` for route helpers in concerns/callbacks that may execute inside a mounted engine.** And when adding deny-by-default authorization, explicitly exempt engine controllers that you don't control.
