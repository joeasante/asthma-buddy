# frozen_string_literal: true

class Admin::SiteSettingsController < Admin::BaseController
  after_action :verify_authorized

  def toggle_registration
    authorize :site_setting, :toggle_registration?
    is_open = SiteSetting.toggle_registration!

    message = "Registration is now #{is_open ? 'open' : 'closed'}."

    respond_to do |format|
      format.html { redirect_back fallback_location: admin_root_path, notice: message }
      format.json { render json: { registration_open: is_open, message: message } }
    end
  end
end
