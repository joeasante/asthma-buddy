# Phase 27: Multi-Factor Authentication - Research

**Researched:** 2026-03-14
**Domain:** TOTP-based two-factor authentication (Rails 8, rotp, rqrcode)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Use `rotp` gem for TOTP generation/verification
- Use `rqrcode` gem for QR code generation
- MFA must use "pending" session state -- don't authenticate before TOTP verification
- TOTP secrets encrypted via Rails Active Record Encryption

### Claude's Discretion
- MFA setup location (dedicated security page vs section in account settings)
- Login challenge screen design and layout
- Recovery codes presentation (dedicated page vs modal, download UX)
- QR code styling and presentation
- Recovery code regeneration flow

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

## Summary

This phase adds TOTP-based two-factor authentication to Asthma Buddy using `rotp` (TOTP generation/verification) and `rqrcode` (QR code rendering). The core flow is: user enables MFA from settings, scans a QR code, confirms with a valid TOTP code, and receives 10 recovery codes. On subsequent logins, after password verification the user is held in a "pending MFA" state (session stores user ID but no authenticated session is created) until they enter a valid TOTP code or recovery code.

The app already has Rails 8 built-in authentication (has_secure_password, Session model, Authentication concern) and Pundit authorization. The MFA implementation adds columns to the users table (encrypted otp_secret, otp_required_for_login flag, encrypted recovery codes, last_otp_at timestamp), a new "Security" section on the Settings page, a dedicated MFA challenge controller for the login interception, and modifications to the SessionsController to hold users in a pending state when MFA is enabled.

Active Record Encryption is NOT yet configured in this app -- credentials lack the required encryption keys. This must be set up before `encrypts :otp_secret` will work.

**Primary recommendation:** Implement MFA as a three-controller design: `Settings::SecurityController` (enable/disable MFA, show recovery codes), `MfaChallengeController` (post-login TOTP verification), and modifications to `SessionsController` (pending state redirection). Generate AR encryption keys first.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| rotp | ~> 6.3 | TOTP generation/verification per RFC 6238 | De facto Ruby TOTP library, 160M+ downloads, implements RFC 4226/6238 |
| rqrcode | ~> 3.2 | QR code generation from provisioning URI | Standard Ruby QR library, pure Ruby, no native deps |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SecureRandom (stdlib) | built-in | Generate recovery codes | Recovery code generation |
| Active Record Encryption | Rails 8.1 built-in | Encrypt otp_secret and recovery_codes at rest | Mandatory for TOTP secrets per locked decision |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| rotp + rqrcode | devise-two-factor | Full-featured but brings Devise dependency; this app uses Rails 8 built-in auth |
| rotp + rqrcode | active_model_otp | Higher-level abstraction but less control over pending session flow |
| SVG QR inline | PNG QR via ChunkyPNG | SVG is simpler (no binary dependency), scales perfectly, renders inline in HTML |

**Installation:**
```bash
bundle add rotp rqrcode
```

## Architecture Patterns

### Recommended Project Structure
```
app/
  controllers/
    sessions_controller.rb          # Modified: pending MFA redirect
    mfa_challenge_controller.rb     # New: TOTP verification after login
    settings/
      security_controller.rb        # New: enable/disable MFA, recovery codes
  models/
    user.rb                         # Modified: encrypts, MFA methods
  views/
    mfa_challenge/
      new.html.erb                  # TOTP entry form
    settings/
      security/
        show.html.erb               # Security settings page (MFA status, enable/disable)
        setup.html.erb              # QR code + confirmation form
        recovery_codes.html.erb     # Display/download recovery codes
    settings/
      show.html.erb                 # Modified: add Security nav card
    sessions/
      new.html.erb                  # Unchanged (password login stays the same)
  helpers/
    mfa_helper.rb                   # QR code SVG rendering helper
db/
  migrate/
    XXXX_add_mfa_columns_to_users.rb
    XXXX_add_pending_mfa_to_sessions.rb  # (only if using DB-backed pending state)
```

### Pattern 1: Pending MFA Session State (CRITICAL -- locked decision)
**What:** After password verification, store user_id in Rails session hash but do NOT create a Session record or set the session cookie. The user is "pending MFA" -- they cannot access any authenticated routes.
**When to use:** Every login for MFA-enabled users.
**Example:**
```ruby
# Source: community pattern from https://keygen.sh/blog/how-to-implement-totp-2fa-in-rails-using-rotp/
# SessionsController#create -- modified flow
def create
  user = User.authenticate_by(params.permit(:email_address, :password))
  # ... existing validation (nil user, allowed_email?, email_verified?) ...

  if user.otp_required_for_login?
    # Store user ID in session but do NOT call start_new_session_for
    session[:pending_mfa_user_id] = user.id
    redirect_to new_mfa_challenge_path
    return
  end

  # Normal login flow (no MFA)
  start_new_session_for user
  # ...
end
```

### Pattern 2: MFA Challenge Controller
**What:** Dedicated controller that verifies TOTP code or recovery code, then completes authentication.
**When to use:** After password verification for MFA-enabled users.
**Example:**
```ruby
# Source: synthesized from rotp docs + community patterns
class MfaChallengeController < ApplicationController
  skip_pundit
  allow_unauthenticated_access
  rate_limit to: 5, within: 1.minute, only: :create

  before_action :require_pending_mfa

  def new
    # Render TOTP entry form
  end

  def create
    user = User.find_by(id: session[:pending_mfa_user_id])
    return redirect_to new_session_path unless user

    if user.verify_otp(params[:otp_code])
      session.delete(:pending_mfa_user_id)
      start_new_session_for user
      session[:last_seen_at] = Time.current
      user.update_columns(last_sign_in_at: Time.current)
      User.where(id: user.id).update_all("sign_in_count = sign_in_count + 1")
      redirect_to after_authentication_url
    elsif user.verify_recovery_code(params[:otp_code])
      session.delete(:pending_mfa_user_id)
      start_new_session_for user
      session[:last_seen_at] = Time.current
      user.update_columns(last_sign_in_at: Time.current)
      User.where(id: user.id).update_all("sign_in_count = sign_in_count + 1")
      redirect_to after_authentication_url, notice: "Recovery code used. You have #{user.recovery_codes_remaining} remaining."
    else
      flash.now[:alert] = "Invalid code. Please try again."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_pending_mfa
    redirect_to new_session_path unless session[:pending_mfa_user_id]
  end
end
```

### Pattern 3: TOTP Setup Flow (Enable MFA)
**What:** Three-step flow: generate secret + show QR, user confirms with valid code, show recovery codes.
**When to use:** When user enables MFA from security settings.
**Example:**
```ruby
# Source: rotp README + rqrcode README
class Settings::SecurityController < Settings::BaseController
  def show
    authorize :settings, :show?
    # Show MFA status and enable/disable buttons
  end

  def setup
    authorize :settings, :show?
    # Generate a new secret (store temporarily in session, NOT in DB yet)
    session[:pending_otp_secret] = ROTP::Base32.random
    totp = ROTP::TOTP.new(session[:pending_otp_secret], issuer: "Asthma Buddy")
    @provisioning_uri = totp.provisioning_uri(Current.user.email_address)
    @qr_svg = RQRCode::QRCode.new(@provisioning_uri).as_svg(
      module_size: 4,
      use_path: true,
      fill: "ffffff"
    )
  end

  def confirm_setup
    authorize :settings, :show?
    secret = session[:pending_otp_secret]
    return redirect_to settings_security_path, alert: "Setup expired." unless secret

    totp = ROTP::TOTP.new(secret, issuer: "Asthma Buddy")
    if totp.verify(params[:otp_code], drift_behind: 15)
      Current.user.enable_mfa!(secret)
      session.delete(:pending_otp_secret)
      redirect_to recovery_codes_settings_security_path
    else
      flash.now[:alert] = "Invalid code. Scan the QR code and try again."
      @provisioning_uri = totp.provisioning_uri(Current.user.email_address)
      @qr_svg = RQRCode::QRCode.new(@provisioning_uri).as_svg(
        module_size: 4, use_path: true, fill: "ffffff"
      )
      render :setup, status: :unprocessable_entity
    end
  end

  def recovery_codes
    authorize :settings, :show?
    @recovery_codes = Current.user.recovery_codes
  end

  def disable
    authorize :settings, :show?
    # Re-authenticate with password before disabling
  end

  def confirm_disable
    authorize :settings, :show?
    unless Current.user.authenticate(params[:password])
      flash.now[:alert] = "Incorrect password."
      render :disable, status: :unprocessable_entity
      return
    end
    Current.user.disable_mfa!
    redirect_to settings_security_path, notice: "Two-factor authentication disabled."
  end
end
```

### Pattern 4: User Model MFA Methods
**What:** Encapsulate TOTP verification, recovery code management, and encryption on the User model.
**Example:**
```ruby
# Source: rotp docs, Rails AR Encryption docs
class User < ApplicationRecord
  encrypts :otp_secret, deterministic: false
  encrypts :otp_recovery_codes, deterministic: false

  def otp_required_for_login?
    otp_secret.present? && otp_required_for_login
  end

  def verify_otp(code)
    return false unless otp_secret.present? && code.present?
    totp = ROTP::TOTP.new(otp_secret, issuer: "Asthma Buddy")
    result = totp.verify(code.to_s, drift_behind: 15, after: last_otp_at.to_i)
    if result
      update!(last_otp_at: Time.at(result))
      true
    else
      false
    end
  end

  def verify_recovery_code(code)
    return false unless code.present?
    codes = recovery_codes_array
    normalized = code.to_s.strip.downcase.delete("-")
    index = codes.index(normalized)
    return false unless index
    codes.delete_at(index)
    update!(otp_recovery_codes: codes.join(","))
    true
  end

  def enable_mfa!(secret)
    codes = generate_recovery_codes
    update!(
      otp_secret: secret,
      otp_required_for_login: true,
      otp_recovery_codes: codes.join(","),
      last_otp_at: nil
    )
    codes
  end

  def disable_mfa!
    update!(
      otp_secret: nil,
      otp_required_for_login: false,
      otp_recovery_codes: nil,
      last_otp_at: nil
    )
  end

  def recovery_codes_remaining
    recovery_codes_array.size
  end

  def recovery_codes
    recovery_codes_array
  end

  private

  def recovery_codes_array
    (otp_recovery_codes || "").split(",").reject(&:blank?)
  end

  def generate_recovery_codes
    10.times.map { SecureRandom.hex(5) } # 10 hex chars = "a1b2c3d4e5"
  end
end
```

### Pattern 5: QR Code Rendering as Inline SVG
**What:** Render QR code as inline SVG in the setup view -- no image endpoint needed.
**Example:**
```ruby
# Source: rqrcode README (v3.2)
# In helper or directly in controller:
qr = RQRCode::QRCode.new(provisioning_uri)
svg = qr.as_svg(
  module_size: 4,
  use_path: true,    # Smaller SVG output
  fill: "ffffff",
  color: "000000",
  viewbox: true       # Enables CSS scaling
)
# In view: <%= svg.html_safe %>
```

### Anti-Patterns to Avoid
- **Storing pending secret in DB before confirmation:** Never write the OTP secret to the user record until the user confirms with a valid code. Store in `session[:pending_otp_secret]` during setup.
- **Creating an authenticated session before MFA verification:** The locked decision explicitly requires a "pending" state. Use `session[:pending_mfa_user_id]` only -- do NOT call `start_new_session_for`.
- **Plaintext recovery codes in DB:** Recovery codes must also be encrypted at rest (use `encrypts :otp_recovery_codes`).
- **Not rate-limiting the MFA challenge:** TOTP codes are 6 digits -- brute force is viable without rate limiting.
- **Skipping drift_behind:** Authenticator app clocks drift. Allow 15 seconds behind to avoid user frustration.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| TOTP generation/verification | Custom HMAC-SHA1 implementation | `rotp` gem | RFC 6238 compliance, time drift handling, Base32 encoding |
| QR code generation | Manual QR matrix calculation | `rqrcode` gem | QR encoding is complex (error correction, masking, versioning) |
| Provisioning URI format | Manual `otpauth://` string building | `ROTP::TOTP#provisioning_uri` | Standard format with proper URL encoding, issuer handling |
| Recovery code generation | Custom random string logic | `SecureRandom.hex(5)` | Cryptographically secure randomness |
| Secret encryption at rest | Custom AES encryption | `encrypts` (Rails AR Encryption) | Built-in key management, transparent encrypt/decrypt |

**Key insight:** TOTP is a security-critical feature where implementation errors create vulnerabilities. The `rotp` gem is battle-tested against RFC test vectors. Never hand-roll cryptographic operations.

## Common Pitfalls

### Pitfall 1: Active Record Encryption Not Configured
**What goes wrong:** `encrypts :otp_secret` silently fails or raises errors because encryption keys are missing from credentials.
**Why it happens:** This app's `credentials.yml.enc` does NOT currently contain `active_record_encryption` keys.
**How to avoid:** Run `bin/rails db:encryption:init` and add the output to credentials BEFORE adding `encrypts` declarations. Verify with a Rails console test.
**Warning signs:** Encrypted columns storing plaintext, or `ActiveRecord::Encryption::Errors::Configuration` errors.

### Pitfall 2: OTP Replay Attack
**What goes wrong:** An attacker intercepts a valid TOTP code and replays it within the 30-second window.
**Why it happens:** TOTP codes are valid for 30 seconds; without replay prevention, the same code works multiple times.
**How to avoid:** Track `last_otp_at` timestamp and pass it as the `after:` parameter to `totp.verify`. The `verify` method returns the timestamp of the code, which you store for next comparison.
**Warning signs:** Same code working twice in succession.

### Pitfall 3: Pending MFA State Leaking to Authenticated Routes
**What goes wrong:** A user in "pending MFA" state can access authenticated pages by navigating directly.
**Why it happens:** `session[:pending_mfa_user_id]` is set, but the `Authentication` concern only checks for a valid Session record. Without extra guards, users without a Session record simply get redirected to login -- they cannot access authenticated routes. However, ensure `session[:pending_mfa_user_id]` is cleaned up on timeout.
**How to avoid:** The existing `require_authentication` flow already prevents access since `start_new_session_for` is never called. Add cleanup: expire `pending_mfa_user_id` after a short window (e.g., 5 minutes).
**Warning signs:** Stale pending MFA sessions lingering indefinitely.

### Pitfall 4: Recovery Codes Not Normalized
**What goes wrong:** User enters a recovery code with dashes or mixed case that doesn't match stored format.
**Why it happens:** Recovery codes are often displayed with dashes for readability (e.g., "a1b2c-3d4e5") but stored without them.
**How to avoid:** Normalize both sides: strip whitespace, downcase, remove dashes before comparison.
**Warning signs:** Valid recovery codes rejected.

### Pitfall 5: QR Code Not Scanning in Dark Mode
**What goes wrong:** QR code is unreadable because the SVG inherits dark-mode colors.
**Why it happens:** SVG fill/color set to CSS variables or inherit from parent.
**How to avoid:** Hard-code black-on-white colors in the SVG: `color: "000000", fill: "ffffff"`. Wrap in a white-background container.
**Warning signs:** QR code appears as dark-on-dark in dark themes.

### Pitfall 6: Encrypted Column Too Short
**What goes wrong:** Migration creates a `string` column (default 255 chars) but encrypted payload exceeds it.
**Why it happens:** AR Encryption adds ~255 bytes of metadata overhead, and recovery codes (10 codes) plus Base64 encoding can exceed 255 chars.
**How to avoid:** Use `text` type for encrypted columns (unlimited length), not `string`.
**Warning signs:** `ActiveRecord::ValueTooLong` errors on save.

### Pitfall 7: Forgetting to Clear Pending MFA on Logout/New Login
**What goes wrong:** User abandons MFA challenge, goes to login page, logs in as different user -- but `pending_mfa_user_id` still points to first user.
**Why it happens:** SessionsController#create doesn't clear stale pending state.
**How to avoid:** Clear `session[:pending_mfa_user_id]` at the start of `SessionsController#new` and `#create`.
**Warning signs:** Wrong user gets authenticated after MFA challenge.

## Code Examples

### Migration: Add MFA columns to users
```ruby
# Source: Rails AR Encryption docs + rotp patterns
class AddMfaColumnsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_secret, :text          # encrypted via AR Encryption -- use text, not string
    add_column :users, :otp_required_for_login, :boolean, default: false, null: false
    add_column :users, :otp_recovery_codes, :text  # encrypted, comma-separated
    add_column :users, :last_otp_at, :datetime     # for replay prevention
  end
end
```

### Setting up Active Record Encryption keys
```bash
# Source: https://guides.rubyonrails.org/active_record_encryption.html
# Run this to generate keys:
bin/rails db:encryption:init

# Output looks like:
# active_record_encryption:
#   primary_key: <key>
#   deterministic_key: <key>
#   key_derivation_salt: <salt>

# Add the output to credentials:
bin/rails credentials:edit
# Paste the active_record_encryption block
```

### ROTP: Generate secret and provisioning URI
```ruby
# Source: rotp README (v6.3) https://github.com/mdp/rotp
secret = ROTP::Base32.random  # => "JBSWY3DPEHPK3PXP" (32-char base32)
totp = ROTP::TOTP.new(secret, issuer: "Asthma Buddy")
uri = totp.provisioning_uri("user@example.com")
# => "otpauth://totp/Asthma%20Buddy:user%40example.com?secret=JBSWY3DPEHPK3PXP&issuer=Asthma%20Buddy"
```

### ROTP: Verify with replay prevention
```ruby
# Source: rotp README (v6.3)
totp = ROTP::TOTP.new(user.otp_secret, issuer: "Asthma Buddy")
timestamp = totp.verify(code, drift_behind: 15, after: user.last_otp_at.to_i)
# Returns integer timestamp if valid, nil if invalid
# Store timestamp to prevent replay:
user.update!(last_otp_at: Time.at(timestamp)) if timestamp
```

### RQRCode: Generate inline SVG
```ruby
# Source: rqrcode README (v3.2) https://github.com/whomwah/rqrcode
qr = RQRCode::QRCode.new(provisioning_uri)
svg_string = qr.as_svg(
  module_size: 4,
  use_path: true,
  fill: "ffffff",
  color: "000000",
  viewbox: true
)
# Render in ERB: <%= svg_string.html_safe %>
```

### Recovery code generation
```ruby
# Source: standard Ruby pattern
def generate_recovery_codes
  10.times.map { SecureRandom.hex(5) }
  # => ["a1b2c3d4e5", "f6a7b8c9d0", ...]
end
```

### Recovery code download (text file)
```ruby
# Source: standard Rails pattern
def download_recovery_codes
  codes = Current.user.recovery_codes
  filename = "asthma-buddy-recovery-codes.txt"
  content = "Asthma Buddy Recovery Codes\n"
  content += "Generated: #{Time.current.strftime('%Y-%m-%d')}\n"
  content += "Each code can only be used once.\n\n"
  content += codes.map.with_index(1) { |code, i| "#{i.to_s.rjust(2)}. #{code}" }.join("\n")
  send_data content, filename: filename, type: "text/plain"
end
```

### Routes
```ruby
# Source: synthesized for this app's route conventions
scope "/settings", module: :settings, as: :settings do
  resource :security, only: [:show] do
    get :setup
    post :confirm_setup
    get :recovery_codes
    get :disable
    post :confirm_disable
    get :regenerate_recovery_codes
    post :confirm_regenerate_recovery_codes
    post :download_recovery_codes
  end
end

resource :mfa_challenge, only: [:new, :create], path: "mfa-challenge"
```

## Discretion Recommendations

### MFA Setup Location
**Recommendation:** Dedicated "Security" card on the Settings page (alongside existing Profile and Medications cards), linking to `settings/security/show`. This follows the established settings-nav-grid pattern.
**Rationale:** Security settings are conceptually separate from profile/medications. A dedicated section scales to future security features (password change, session management).

### Login Challenge Screen Design
**Recommendation:** Use the existing `auth-card` pattern (same as login page). Show "Two-Factor Authentication" heading, a single 6-digit code field, a submit button, and a "Use a recovery code" link/toggle.
**Rationale:** Consistent with existing auth screens. Minimal -- user is already partially authenticated.

### Recovery Codes Presentation
**Recommendation:** Dedicated page (`settings/security/recovery_codes`) shown immediately after MFA setup, with a "Download" button that triggers a text file download. Also accessible from the Security settings page.
**Rationale:** Dedicated page ensures user sees all codes. Download button provides a save mechanism. No modal -- modals can be accidentally dismissed.

### QR Code Styling
**Recommendation:** Black-on-white QR code centered on the setup page, wrapped in a white container with padding. Hard-coded colors (not CSS variables) to prevent dark-mode issues. Show the secret key as text below the QR code for manual entry.
**Rationale:** QR codes must be high-contrast for scanning. Manual entry fallback is essential for users who can't scan.

### Recovery Code Regeneration
**Recommendation:** Available from Security settings page. Requires password re-authentication. Generates new codes and invalidates all old ones. Shows new codes on a dedicated page with download option.
**Rationale:** Users may lose their codes. Regeneration should be deliberately gated (password required) since it invalidates existing codes.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom AES encryption for secrets | `encrypts` (Rails AR Encryption) | Rails 7.0+ (2021) | No custom crypto code needed |
| Separate encryption gems (attr_encrypted) | Built-in AR Encryption | Rails 7.0+ | One fewer dependency |
| devise-two-factor (Devise-coupled) | rotp + custom controllers | Always available | No Devise dependency; works with Rails 8 built-in auth |
| HOTP (counter-based) | TOTP (time-based) | Industry standard since ~2015 | Better UX, no counter sync issues |

**Deprecated/outdated:**
- `attr_encrypted` gem: Superseded by Rails AR Encryption for new projects
- SMS-based 2FA: Known insecure (SIM swap attacks); TOTP is the standard
- `devise-two-factor`: Still maintained but unnecessary without Devise

## Open Questions

1. **Pending MFA session expiry**
   - What we know: `session[:pending_mfa_user_id]` should expire after some time
   - What's unclear: Whether to use a separate timestamp or rely on Rails session expiry
   - Recommendation: Store `session[:pending_mfa_at] = Time.current.to_i` alongside the user ID, and reject if older than 5 minutes in the MFA challenge controller. Simple and explicit.

2. **JSON API support for MFA**
   - What we know: The app supports `format.json` on login. MFA adds a second step.
   - What's unclear: Whether JSON clients need MFA challenge support now
   - Recommendation: For JSON login, return a specific status/error code (e.g., `{ error: "MFA required", mfa_token: ... }`) so future API clients can handle it. At minimum, return 403 with an "MFA required" message. The full API key phase (Phase 28+) will address this properly.

3. **Pundit policy for security settings**
   - What we know: All controllers require Pundit authorization. Settings show uses `authorize :settings, :show?`
   - What's unclear: Whether security actions need a separate policy
   - Recommendation: Reuse the existing `:settings` policy with `show?` -- all security actions are user-scoped (users can only manage their own MFA). No admin override needed.

## Sources

### Primary (HIGH confidence)
- rotp gem README (v6.3.0) - https://github.com/mdp/rotp - TOTP API, provisioning URI, verify with drift, replay prevention
- rqrcode gem README (v3.2.0) - https://github.com/whomwah/rqrcode - QR generation API, SVG output options
- Rails Active Record Encryption guide - https://guides.rubyonrails.org/active_record_encryption.html - Setup, `encrypts` declaration, key generation
- RubyGems.org rotp page - https://rubygems.org/gems/rotp - Version 6.3.0 confirmed
- RubyGems.org rqrcode page - https://rubygems.org/gems/rqrcode - Version 3.2.0 confirmed

### Secondary (MEDIUM confidence)
- Keygen TOTP 2FA guide - https://keygen.sh/blog/how-to-implement-totp-2fa-in-rails-using-rotp/ - Verified patterns for rotp usage, encrypts integration
- Reinteractive 2FA tutorial - https://reinteractive.com/articles/tutorial-series-for-experienced-rails-developers/rails-2fa-authenticator-app - Pending session pattern via session[:otp_user_id]

### Tertiary (LOW confidence)
- None -- all findings verified against primary sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - rotp and rqrcode are well-documented, stable gems with verified APIs
- Architecture: HIGH - Authentication concern and SessionsController are fully understood from reading the codebase; pending session pattern is well-established
- Pitfalls: HIGH - AR Encryption key absence verified by reading credentials; encrypted column sizing verified in Rails docs; replay prevention documented in rotp README
- Discretion areas: HIGH - Settings page pattern well-understood from reading existing views/controllers

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (30 days -- stable domain, minimal library churn)
