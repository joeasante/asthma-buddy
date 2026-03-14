# frozen_string_literal: true

class Admin::SiteSettingsController < Admin::BaseController
  def toggle_registration
    authorize :site_setting, :toggle_registration?
    SiteSetting.toggle_registration!
    redirect_back fallback_location: admin_root_path,
                  notice: "Registration is now #{SiteSetting.registration_open? ? 'open' : 'closed'}."
  end
end
