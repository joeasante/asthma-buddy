# frozen_string_literal: true

class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]
  skip_before_action :check_session_freshness, only: %i[ index ]

  def index
    redirect_to dashboard_path if authenticated?
  end
end
