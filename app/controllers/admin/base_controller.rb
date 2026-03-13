# frozen_string_literal: true

# Base controller for admin-only engines (Mission Control Jobs).
# Uses the app's existing session authentication, then verifies the logged-in
# user is the configured admin. Works over any URL (Tailscale, localhost, etc.)
# without requiring HTTPS for HTTP Basic Auth browser prompts.
class Admin::BaseController < ApplicationController
  before_action :require_admin

  private

    def require_admin
      redirect_to root_path unless Current.user&.admin?
    end
end
