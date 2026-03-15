# frozen_string_literal: true

class Settings::ApiKeysController < Settings::BaseController
  def show
    authorize :api_key
    @has_key = Current.user.api_key_active?
    @key_created_at = Current.user.api_key_created_at
    @key_expires_at = Current.user.api_key_expires_at
  end

  def create
    authorize :api_key, :create?
    @plaintext_key = Current.user.generate_api_key!
    @has_key = true
    @key_created_at = Current.user.api_key_created_at
    @key_expires_at = Current.user.api_key_expires_at
    response.headers["Cache-Control"] = "no-store"
    Rails.logger.info("[API Key] action=generate user=#{Current.user.id} ip=#{request.remote_ip}")
    flash.now[:notice] = "API key generated. Copy it now — it won't be shown again."
    render :show
  end

  def destroy
    authorize :api_key, :destroy?
    Current.user.revoke_api_key!
    Rails.logger.info("[API Key] action=revoke user=#{Current.user.id} ip=#{request.remote_ip}")
    redirect_to settings_api_key_path, notice: "API key revoked."
  end
end
