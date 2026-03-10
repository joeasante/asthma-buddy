# frozen_string_literal: true

class CookieNoticesController < ApplicationController
  allow_unauthenticated_access

  def dismiss
    session[:cookie_notice_shown] = true
    head :no_content
  end
end
