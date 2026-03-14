# frozen_string_literal: true

# Base controller for admin-only engines (Mission Control Jobs).
# Uses the app's existing session authentication, then verifies the logged-in
# user is the configured admin. Works over any URL (Tailscale, localhost, etc.)
# without requiring HTTPS for HTTP Basic Auth browser prompts.
class Admin::BaseController < ApplicationController
  # Belt-and-suspenders: require_admin provides immediate redirect with friendly message;
  # Pundit authorize is the policy safety net that catches any bypass.
  before_action :require_admin

  private

    def require_admin
      unless Current.user&.admin?
        Rails.logger.warn "[security] Non-admin access attempt to #{request.path} by user #{Current.user&.id || 'anonymous'}"
        respond_to do |format|
          format.html { redirect_to root_path, alert: "You do not have access to that page." }
          format.json { render json: { error: "Forbidden" }, status: :forbidden }
        end
      end
    end
end
