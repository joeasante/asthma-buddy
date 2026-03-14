# frozen_string_literal: true

require "test_helper"

class Settings::SecurityControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    @mfa_user = users(:mfa_user)
    @otp_secret = ROTP::Base32.random
    @mfa_user.enable_mfa!(@otp_secret)
  end

  # -- MFA Status Display --

  test "GET /settings/security shows MFA status disabled for non-MFA user" do
    sign_in_as(@user)
    get settings_security_path
    assert_response :success
    assert_select ".badge--disabled", "Disabled"
    assert_select "a[href=?]", setup_settings_security_path
  end

  test "GET /settings/security shows MFA status enabled for MFA user" do
    sign_in_as(@mfa_user)
    get settings_security_path
    assert_response :success
    assert_select ".badge--enabled", "Enabled"
    assert_select "a[href=?]", disable_settings_security_path
  end

  # -- MFA Setup Flow --

  test "GET /settings/security/setup renders QR code and manual key" do
    sign_in_as(@user)
    get setup_settings_security_path
    assert_response :success
    assert_select "svg"
    assert_select "code.mfa-manual-key"
    assert_not_nil session[:pending_otp_secret]
  end

  test "POST /settings/security/confirm_setup with valid code enables MFA" do
    sign_in_as(@user)

    # Visit setup to generate pending secret in session
    get setup_settings_security_path
    pending_secret = session[:pending_otp_secret]
    assert_not_nil pending_secret

    # Generate a valid TOTP code from the pending secret
    code = ROTP::TOTP.new(pending_secret, issuer: "Asthma Buddy").now

    post confirm_setup_settings_security_path, params: { otp_code: code }
    assert_redirected_to recovery_codes_settings_security_path
    assert @user.reload.otp_required_for_login?
  end

  test "POST /settings/security/confirm_setup with invalid code re-renders setup" do
    sign_in_as(@user)
    get setup_settings_security_path

    post confirm_setup_settings_security_path, params: { otp_code: "000000" }
    assert_response :unprocessable_entity
    assert_not @user.reload.otp_required_for_login?
  end

  test "POST /settings/security/confirm_setup without pending secret redirects" do
    sign_in_as(@user)
    post confirm_setup_settings_security_path, params: { otp_code: "123456" }
    assert_redirected_to settings_security_path
    assert_match "expired", flash[:alert]
  end

  # -- Recovery Codes --

  test "GET /settings/security/recovery_codes shows codes for MFA user" do
    sign_in_as(@mfa_user)
    get recovery_codes_settings_security_path
    assert_response :success
    assert_select ".mfa-recovery-code", count: @mfa_user.recovery_codes.size
  end

  test "POST /settings/security/download_recovery_codes returns text file" do
    sign_in_as(@mfa_user)
    post download_recovery_codes_settings_security_path
    assert_response :success
    assert_includes response.content_type, "text/plain"
    assert_includes response.body, "Asthma Buddy Recovery Codes"
  end

  test "GET /settings/security/recovery_codes requires authentication" do
    get recovery_codes_settings_security_path
    assert_redirected_to new_session_path
  end

  # -- Disable MFA --

  test "GET /settings/security/disable renders password form" do
    sign_in_as(@mfa_user)
    get disable_settings_security_path
    assert_response :success
    assert_select "input[type=password]"
  end

  test "POST /settings/security/confirm_disable with correct password disables MFA" do
    sign_in_as(@mfa_user)
    post confirm_disable_settings_security_path, params: { password: "password123" }
    assert_redirected_to settings_security_path
    assert_not @mfa_user.reload.otp_required_for_login?
  end

  test "POST /settings/security/confirm_disable with wrong password re-renders" do
    sign_in_as(@mfa_user)
    post confirm_disable_settings_security_path, params: { password: "wrongpassword" }
    assert_response :unprocessable_entity
    assert @mfa_user.reload.otp_required_for_login?
  end

  # -- Regenerate Recovery Codes --

  test "POST /settings/security/confirm_regenerate with correct password regenerates codes" do
    sign_in_as(@mfa_user)
    old_codes = @mfa_user.recovery_codes

    post confirm_regenerate_recovery_codes_settings_security_path, params: { password: "password123" }
    assert_redirected_to recovery_codes_settings_security_path
    assert_not_equal old_codes, @mfa_user.reload.recovery_codes
  end

  test "POST /settings/security/confirm_regenerate with wrong password fails" do
    sign_in_as(@mfa_user)
    post confirm_regenerate_recovery_codes_settings_security_path, params: { password: "wrong" }
    assert_response :unprocessable_entity
  end
end
