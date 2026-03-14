# frozen_string_literal: true

class MfaChallengeController < ApplicationController
  skip_pundit
  allow_unauthenticated_access
  rate_limit to: 5, within: 1.minute, only: :create, with: -> {
    respond_to do |format|
      format.html { redirect_to new_mfa_challenge_path, alert: "Too many attempts. Try again later." }
      format.json { render json: { error: "Too many attempts. Try again later." }, status: :too_many_requests }
    end
  }

  before_action :require_pending_mfa

  def new
  end

  def create
    user = User.find_by(id: session[:pending_mfa_user_id])
    unless user
      return respond_to do |format|
        format.html { redirect_to new_session_path }
        format.json { render json: { error: "Session expired" }, status: :unauthorized }
      end
    end

    if user.verify_otp(params[:otp_code])
      complete_mfa_login(user)
      respond_to do |format|
        format.html { redirect_to after_authentication_url }
        format.json { render json: { message: "Signed in." }, status: :created }
      end
    elsif user.verify_recovery_code(params[:otp_code])
      complete_mfa_login(user)
      respond_to do |format|
        format.html { redirect_to after_authentication_url, notice: "Recovery code used. You have #{user.recovery_codes_remaining} remaining." }
        format.json { render json: { message: "Signed in.", recovery_codes_remaining: user.recovery_codes_remaining }, status: :created }
      end
    else
      respond_to do |format|
        format.html do
          flash.now[:alert] = "Invalid code. Please try again."
          render :new, status: :unprocessable_entity
        end
        format.json { render json: { error: "Invalid code" }, status: :unauthorized }
      end
    end
  end

  private

  def require_pending_mfa
    unless session[:pending_mfa_user_id]
      return respond_to do |format|
        format.html { redirect_to new_session_path }
        format.json { render json: { error: "No pending MFA session" }, status: :unauthorized }
      end
    end

    if session[:pending_mfa_at].blank? || (Time.current.to_i - session[:pending_mfa_at].to_i > 300)
      session.delete(:pending_mfa_user_id)
      session.delete(:pending_mfa_at)
      respond_to do |format|
        format.html { redirect_to new_session_path, alert: "Your verification session expired. Please sign in again." }
        format.json { render json: { error: "MFA session expired" }, status: :unauthorized }
      end
    end
  end

  def complete_mfa_login(user)
    session.delete(:pending_mfa_user_id)
    session.delete(:pending_mfa_at)
    complete_sign_in(user)
  end
end
