# frozen_string_literal: true

class HomeController < ApplicationController
  skip_pundit
  allow_unauthenticated_access only: %i[ index ]

  def index
    redirect_to dashboard_path if authenticated?
  end
end
