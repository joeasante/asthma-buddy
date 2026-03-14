# frozen_string_literal: true

class Settings::SecurityController < Settings::BaseController
  before_action -> { authorize :settings, :show? }
  before_action :require_mfa_disabled, only: %i[setup confirm_setup]
  before_action :require_mfa_enabled, only: %i[recovery_codes download_recovery_codes disable confirm_disable regenerate_recovery_codes confirm_regenerate_recovery_codes]
  rate_limit to: 5, within: 1.minute, only: %i[confirm_disable confirm_regenerate_recovery_codes], with: -> {
    redirect_to settings_security_path, alert: "Too many attempts. Try again later."
  }

  def show
  end

  def setup
    session[:pending_otp_secret] ||= ROTP::Base32.random
    prepare_setup_view(session[:pending_otp_secret])
  end

  def confirm_setup
    secret = session[:pending_otp_secret]
    unless secret
      redirect_to settings_security_path, alert: "Setup expired. Please try again."
      return
    end

    totp = ROTP::TOTP.new(secret, issuer: "Asthma Buddy")
    if totp.verify(params[:otp_code].to_s, drift_behind: 15)
      Current.user.enable_mfa!(secret)
      session.delete(:pending_otp_secret)
      redirect_to recovery_codes_settings_security_path, notice: "Two-factor authentication has been enabled."
    else
      flash.now[:alert] = "Invalid code. Scan the QR code and try again."
      prepare_setup_view(secret)
      render :setup, status: :unprocessable_entity
    end
  end

  def recovery_codes
    @recovery_codes = Current.user.recovery_codes
  end

  def download_recovery_codes
    codes = Current.user.recovery_codes
    content = "Asthma Buddy Recovery Codes\n"
    content += "Generated: #{Time.current.strftime('%Y-%m-%d')}\n"
    content += "Each code can only be used once.\n\n"
    content += codes.map.with_index(1) { |code, i| "#{i.to_s.rjust(2)}. #{code}" }.join("\n")
    send_data content, filename: "asthma-buddy-recovery-codes.txt", type: "text/plain"
  end

  def disable
  end

  def confirm_disable
    unless Current.user.authenticate(params[:password])
      flash.now[:alert] = "Incorrect password."
      render :disable, status: :unprocessable_entity
      return
    end
    Current.user.disable_mfa!
    redirect_to settings_security_path, notice: "Two-factor authentication has been disabled."
  end

  def regenerate_recovery_codes
  end

  def confirm_regenerate_recovery_codes
    unless Current.user.authenticate(params[:password])
      flash.now[:alert] = "Incorrect password."
      render :regenerate_recovery_codes, status: :unprocessable_entity
      return
    end
    Current.user.regenerate_recovery_codes!
    redirect_to recovery_codes_settings_security_path, notice: "New recovery codes generated. Your old codes are no longer valid."
  end

  private

  def prepare_setup_view(secret)
    totp = ROTP::TOTP.new(secret, issuer: "Asthma Buddy")
    @provisioning_uri = totp.provisioning_uri(Current.user.email_address)
    @qr_svg = helpers.mfa_qr_svg(@provisioning_uri)
    @manual_key = secret
  end

  def require_mfa_enabled
    redirect_to settings_security_path, alert: "Two-factor authentication is not enabled." unless Current.user.otp_required_for_login?
  end

  def require_mfa_disabled
    redirect_to settings_security_path, alert: "Two-factor authentication is already enabled." if Current.user.otp_required_for_login?
  end
end
