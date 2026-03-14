# frozen_string_literal: true

class Admin::SiteSettingsController < Admin::BaseController
  def toggle_registration
    authorize :site_setting, :toggle_registration?
    SiteSetting.toggle_registration!

    status_label = SiteSetting.registration_open? ? "open" : "closed"
    message = "Registration is now #{status_label}."

    respond_to do |format|
      format.html { redirect_back fallback_location: admin_root_path, notice: message }
      format.turbo_stream { redirect_back fallback_location: admin_root_path, notice: message }
      format.json { render json: { registration_open: SiteSetting.registration_open?, message: message } }
    end
  end
end
