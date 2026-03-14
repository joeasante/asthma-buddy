# frozen_string_literal: true

# Test-only controller: sets a signed session_id cookie for a given fixture session.
# Guarded so it cannot be used in production even if the route were somehow defined.
# NOTE: The guard is inside the action (not at class level) because Zeitwerk
# eager-loads all files under app/controllers/ in production — a top-level raise
# would crash the boot process.
class Test::SessionsController < ApplicationController
  skip_pundit
  allow_unauthenticated_access

  def create
    raise "Test::SessionsController must not run outside test environment" unless Rails.env.test?

    session_record = Session.find(params[:session_id])
    cookies.signed[:session_id] = {
      value: session_record.id,
      httponly: true,
      secure: false,
      same_site: :lax,
      expires: 2.weeks.from_now
    }
    head :ok
  end
end
