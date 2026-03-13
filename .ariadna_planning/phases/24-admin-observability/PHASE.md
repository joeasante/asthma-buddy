# Phase 24: Admin & Observability

**Status:** Planned
**Created:** 2026-03-13
**Depends on:** Phase 23 (Compliance, Security & Accessibility)

---

## Goal

You are running a live app with real users and have zero visibility into who has registered, when they last used the app, or whether the app is providing value. This phase delivers:

1. **User activity tracking** — `last_sign_in_at` and `sign_in_count` recorded on every login; email notification when a new user registers.
2. **Admin Users page** — in-app user list with admin toggle, last-admin protection, audit logging. Replaces the current Rails-console-only workflow.
3. **Admin Stats dashboard** — total users, new this week/month, weekly/monthly active users; a quick health check for a solo developer.

## Design Principles

- **Custom over gems** — ActiveAdmin and Administrate are heavy, opinionated, and introduce significant maintenance overhead. Your needs are simple: a user list, a stats card, and an admin toggle. `Admin::BaseController` already exists. Build lightweight custom controllers in the existing namespace.
- **Account-level data only** — The admin interface intentionally exposes only account metadata (email, name, dates, activity counts). It does not expose health records. Admin access to health data must be justified, logged, and disclosed in the Privacy Policy.
- **Audit everything** — Every admin action (granting or revoking admin) is logged with actor, target, and timestamp. `Rails.logger.info` is sufficient at this scale; a dedicated `audit_logs` table can be added later if needed.
- **No third-party analytics** — Your user base is small. The metrics you need (total users, WAU, MAU, new signups) are computable in milliseconds from the existing `users` table. No Mixpanel, Amplitude, or Plausible needed.

## GDPR Note

Admins will see user email addresses and activity timestamps. This is personal data under UK GDPR. It is permitted under Art. 6(1)(b) (necessary for contract performance) and Art. 6(1)(f) (legitimate interest in operating the service). The Privacy Policy should disclose that account data may be reviewed by the app operator for support and operational purposes.

---

## Success Criteria

1. Every successful login records `last_sign_in_at = Time.current` and increments `sign_in_count` on the User record.
2. When a new user registers, an email is sent to the admin address configured in Rails credentials.
3. An admin can navigate to `/admin/users`, see all registered users (email, name, joined, last sign-in, sign-in count, admin status), and toggle admin on any user.
4. Self-demotion is blocked; demoting the last admin is blocked with a clear error message.
5. Every admin toggle is logged: `[admin] actor@example.com granted/revoked admin on target@example.com`.
6. An admin can navigate to `/admin` and see: total users, new this week, new this month, WAU (7d), MAU (30d), never-logged-back-in count, a table of recent signups, and a table of most active users.
7. A "Users" link and a "Stats" link appear inside the Mission Control card in Settings, visible only to admins.

---

## Plans

### Plan 24-01: User Activity Tracking & Signup Notification

**Goal:** Record when users last signed in and how often; notify the admin when a new user registers.

**Tasks:**

1. **Migration** — add to users table:
   - `last_sign_in_at:datetime` — nullable, no default; updated on each successful login
   - `sign_in_count:integer, not null, default: 0` — incremented on each successful login

   ```bash
   bin/rails g migration AddActivityTrackingToUsers last_sign_in_at:datetime sign_in_count:integer
   ```
   In the migration: `add_column :users, :sign_in_count, :integer, null: false, default: 0`

2. **`SessionsController#create`** — after `resume_session` / after authentication succeeds, before redirect:
   ```ruby
   Current.user.update_columns(
     last_sign_in_at: Time.current,
     sign_in_count:   Current.user.sign_in_count + 1
   )
   ```
   Use `update_columns` — bypasses validations and callbacks, single SQL UPDATE. Correct for tracking metadata.

3. **`AdminMailer`** — create `app/mailers/admin_mailer.rb`:
   ```ruby
   class AdminMailer < ApplicationMailer
     def new_signup(user)
       @user = user
       @admin_email = Rails.application.credentials.admin_email
       mail(to: @admin_email, subject: "New signup: #{user.email_address}")
     end
   end
   ```
   Create `app/views/admin_mailer/new_signup.html.erb` and `new_signup.text.erb`.
   HTML view: user email, name, joined timestamp, link to `/admin/users`.
   Text view: same as plain text.

4. **`User` model** — `after_create_commit :notify_admin_of_signup`, private:
   ```ruby
   def notify_admin_of_signup
     AdminMailer.new_signup(self).deliver_later
   end
   ```

5. **`credentials.yml.enc`** — document that `admin_email` key is required. Add to README or a `config/credentials.example.yml`.

6. **Tests:**
   - `UserTest`: `last_sign_in_at` is updated on login; `sign_in_count` increments; `after_create_commit` enqueues mailer job.
   - `AdminMailerTest`: `new_signup` renders with correct recipient, subject, and user email in body.
   - `SessionsControllerTest`: successful login updates `last_sign_in_at` and `sign_in_count`.

**Files touched:** `db/migrate/...`, `app/models/user.rb`, `app/controllers/sessions_controller.rb`, `app/mailers/admin_mailer.rb`, `app/views/admin_mailer/`, `test/models/user_test.rb`, `test/mailers/admin_mailer_test.rb`, `test/controllers/sessions_controller_test.rb`

---

### Plan 24-02: Admin Users Page

**Goal:** `/admin/users` — a paginated user list with admin toggle, self/last-admin guards, confirm dialog, audit logging.

**Tasks:**

1. **Routes** — inside the existing `Admin::` namespace (or create it):
   ```ruby
   namespace :admin do
     resources :users, only: [:index] do
       member { patch :toggle_admin }
     end
   end
   ```

2. **`Admin::UsersController`**:
   ```ruby
   class Admin::UsersController < Admin::BaseController
     def index
       @users = User.order(created_at: :desc)
     end

     def toggle_admin
       user = User.find(params[:id])

       if user == Current.user
         return redirect_back(fallback_location: admin_users_path,
                              alert: "You cannot change your own admin status.")
       end

       if User.where(admin: true).count == 1 && user.admin?
         return redirect_back(fallback_location: admin_users_path,
                              alert: "Cannot remove the last admin. Grant admin to another user first.")
       end

       new_state = !user.admin?
       Rails.logger.info "[admin] #{Current.user.email_address} #{new_state ? 'granted' : 'revoked'} admin on #{user.email_address}"
       user.update!(admin: new_state)
       redirect_to admin_users_path,
                   notice: "#{user.email_address} is #{new_state ? 'now' : 'no longer'} an admin."
     end
   end
   ```

3. **View `app/views/admin/users/index.html.erb`**:
   - Page header: "Users" with total count in eyebrow
   - Table with columns: Email · Name · Joined · Last sign in · Sign-ins · Admin
   - Last sign in: display `time_ago_in_words` if set; "Never" if nil
   - Admin column: green "Admin" badge if admin; "—" if not
   - Action column: form button "Make admin" or "Remove admin"
     - Route through `confirm_controller.js`: `data-action="click->confirm#open"`, dialog with appropriate message
     - Disable button on self-row with `disabled` attribute and `title="Cannot change your own admin status"`
   - Use `dom_id(user)` on each `<tr>` for potential future Turbo Stream targeting
   - Empty state: "No users yet" (defensive; in practice this page always has at least the current admin)

4. **Settings link** — in `app/views/settings/show.html.erb`, inside the `if Current.user.admin?` block that shows the Mission Control card, add sub-links:
   ```erb
   <div class="mission-control-links">
     <%= link_to "Jobs", "/jobs" %>
     <%= link_to "Users", admin_users_path %>
   </div>
   ```
   (Exact markup depends on current card structure — add alongside the `/jobs` link.)

5. **Tests** — `test/controllers/admin/users_controller_test.rb`:
   - `index`: admin gets 200; non-admin redirects to root; unauthenticated redirects to login
   - `toggle_admin` success: admin status flipped, redirects with notice
   - `toggle_admin` self: redirect with alert, status unchanged
   - `toggle_admin` last admin: redirect with alert, status unchanged
   - `toggle_admin` unauthenticated: redirects to login
   - `toggle_admin` non-admin: redirects to root

**Files touched:** `config/routes.rb`, `app/controllers/admin/users_controller.rb`, `app/views/admin/users/index.html.erb`, `app/views/settings/show.html.erb`, `test/controllers/admin/users_controller_test.rb`

---

### Plan 24-03: Admin Stats Dashboard

**Goal:** `/admin` — a compact overview of user growth and engagement. Enough to answer "is anyone using this?" in under 3 seconds.

**Tasks:**

1. **Routes** — root of the admin namespace:
   ```ruby
   namespace :admin do
     root "dashboard#index"
     # ... existing resources
   end
   ```

2. **`Admin::DashboardController`**:
   ```ruby
   class Admin::DashboardController < Admin::BaseController
     def index
       @total_users    = User.count
       @new_this_week  = User.where(created_at: 1.week.ago..).count
       @new_this_month = User.where(created_at: 1.month.ago..).count
       @wau            = User.where(last_sign_in_at: 7.days.ago..).count
       @mau            = User.where(last_sign_in_at: 30.days.ago..).count
       @never_returned = User.where(sign_in_count: 1).count
       @recent_signups = User.order(created_at: :desc).limit(10)
       @most_active    = User.order(sign_in_count: :desc).limit(10)
     end
   end
   ```

3. **View `app/views/admin/dashboard/index.html.erb`**:
   - Page header: "Admin" with "Dashboard" subtitle
   - Stat cards grid (2-col mobile, 3-col desktop):
     - Total Users (all time)
     - New This Week
     - New This Month
     - WAU (signed in last 7 days)
     - MAU (signed in last 30 days)
     - Never Returned (signed up but `sign_in_count == 1`) — useful for understanding activation
   - Two tables below the stat grid:
     - **Recent Signups** (10 rows): email, name, joined date
     - **Most Active** (10 rows): email, sign_in_count, last_sign_in_at
   - Minimal styling — reuse `.section-card`, `.pf-stat-strip` or admin-specific CSS

4. **Settings link** — update the admin card in Settings to add a "Stats" sub-link alongside "Users" and "Jobs".

5. **Tests** — `test/controllers/admin/dashboard_controller_test.rb`:
   - `index`: admin gets 200 with correct counts matching fixtures; non-admin redirects; unauthenticated redirects.

**Files touched:** `config/routes.rb`, `app/controllers/admin/dashboard_controller.rb`, `app/views/admin/dashboard/index.html.erb`, `app/views/settings/show.html.erb`, `test/controllers/admin/dashboard_controller_test.rb`
