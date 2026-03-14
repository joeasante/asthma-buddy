# frozen_string_literal: true

class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access only: %i[ show new create ]
  skip_before_action :check_session_freshness, only: %i[ show new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    respond_to do |format|
      format.html { redirect_to new_email_verification_path, alert: "Try again later." }
      format.json { render json: { error: "Too many requests. Try again later." }, status: :too_many_requests }
    end
  }

  def show
    user = User.find_by_token_for(:email_verification, params[:token])

    if user.nil?
      respond_to do |format|
        format.html { redirect_to new_session_path, alert: "Invalid or expired verification link." }
        format.json { render json: { error: "Invalid or expired verification link." }, status: :not_found }
      end
    elsif user.email_verified_at.present?
      respond_to do |format|
        format.html { redirect_to new_session_path, notice: "Email already verified." }
        format.json { render json: { message: "Email already verified." }, status: :ok }
      end
    else
      user.update!(email_verified_at: Time.current)
      respond_to do |format|
        format.html { redirect_to new_session_path, notice: "Email verified! You can now sign in." }
        format.json { render json: { message: "Email verified. You can now sign in." }, status: :ok }
      end
    end
  end

  def new
  end

  def create
    if (user = User.find_by(email_address: params[:email_address])) && user.email_verified_at.nil?
      UserMailer.email_verification(user).deliver_later
    end

    respond_to do |format|
      format.html { redirect_to new_session_path, notice: "Verification email sent (if your account needs it)." }
      format.json { render json: { message: "Verification email sent (if your account needs it)." }, status: :ok }
    end
  end
end
