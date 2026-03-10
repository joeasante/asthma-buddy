# frozen_string_literal: true

class CookieNoticesController < ApplicationController
  allow_unauthenticated_access

  # Session-scoped: the flag is cleared on logout/session reset, so the notice
  # will reappear on the next login. This is intentional — the cookie notice is
  # purely informational (PECR strictly-necessary exemption applies to the
  # session cookie). No consent is required, so reappearance is a minor
  # UX nuisance rather than a compliance issue.
  def dismiss
    session[:cookie_notice_shown] = true
    head :no_content
  end
end
