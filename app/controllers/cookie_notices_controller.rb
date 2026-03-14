# frozen_string_literal: true

class CookieNoticesController < ApplicationController
  skip_pundit
  allow_unauthenticated_access

  # Persistent dismissal: sets a cookie lasting 365 days so the notice never
  # reappears after the user dismisses it, even across sessions. The session
  # cookie itself is strictly necessary and exempt from PECR consent requirements.
  def dismiss
    cookies[:cookie_notice_dismissed] = {
      value: "1",
      expires: 365.days.from_now,
      httponly: true,
      secure: !Rails.env.local?,
      same_site: :lax
    }
    head :no_content
  end
end
