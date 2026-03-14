# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_pundit
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    respond_to do |format|
      format.html { redirect_to new_session_path, alert: "Try again later." }
      format.json { render json: { error: "Too many requests. Try again later." }, status: :too_many_requests }
    end
  }

  def new
    session.delete(:pending_mfa_user_id)
    session.delete(:pending_mfa_at)
  end

  def create
    session.delete(:pending_mfa_user_id)
    session.delete(:pending_mfa_at)

    user = User.authenticate_by(params.permit(:email_address, :password))

    unless user
      return respond_to do |format|
        format.html { redirect_to new_session_path, alert: "Try another email address or password." }
        format.json { render json: { error: "Invalid email address or password" }, status: :unauthorized }
      end
    end

    unless allowed_email?(user.email_address)
      return respond_to do |format|
        format.html { redirect_to new_session_path, alert: "Try another email address or password." }
        format.json { render json: { error: "Invalid email address or password" }, status: :unauthorized }
      end
    end

    unless user.email_verified_at?
      return respond_to do |format|
        format.html { redirect_to new_session_path, alert: "Please verify your email address before signing in. Check your inbox for a verification link." }
        format.json { render json: { error: "Email address not verified. Check your inbox." }, status: :forbidden }
      end
    end

    if user.otp_required_for_login?
      session[:pending_mfa_user_id] = user.id
      session[:pending_mfa_at] = Time.current.to_i
      return respond_to do |format|
        format.html { redirect_to new_mfa_challenge_path }
        format.json { render json: { error: "MFA required", mfa_required: true }, status: :forbidden }
      end
    end

    complete_sign_in(user)
    # NOTE: JSON clients must preserve the Set-Cookie response header (session_id cookie)
    # and replay it on all subsequent authenticated requests. There is no bearer token yet.
    respond_to do |format|
      format.html { redirect_to after_authentication_url }
      format.json { render json: { message: "Signed in." }, status: :created }
    end
  end

  def destroy
    terminate_session
    respond_to do |format|
      format.html { redirect_to new_session_path, status: :see_other }
      format.json { head :no_content }
    end
  end
end
