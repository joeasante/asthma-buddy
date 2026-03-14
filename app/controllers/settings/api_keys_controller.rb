# frozen_string_literal: true

class Settings::ApiKeysController < Settings::BaseController
  before_action -> { authorize :settings, :show? }

  def show
    @has_key = Current.user.api_key_active?
    @key_created_at = Current.user.api_key_created_at
  end

  def create
    @plaintext_key = Current.user.generate_api_key!
    @has_key = true
    @key_created_at = Current.user.api_key_created_at
    flash.now[:notice] = "API key generated. Copy it now — it won't be shown again."
    render :show
  end

  def destroy
    Current.user.revoke_api_key!
    redirect_to settings_api_key_path, notice: "API key revoked."
  end
end
