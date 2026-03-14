# frozen_string_literal: true

# Test-only controller: sets a signed session_id cookie for a given fixture session.
# Guarded so it cannot be used in production even if the route were somehow defined.
raise "Test::SessionsController must not run outside test environment" unless Rails.env.test?

class Test::SessionsController < ApplicationController
  allow_unauthenticated_access

  def create
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
