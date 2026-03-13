# frozen_string_literal: true

class ErrorsController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :set_notification_badge_count
  skip_before_action :check_session_freshness

  def not_found
    render status: :not_found
  end

  def internal_server_error
    render status: :internal_server_error
  end
end
