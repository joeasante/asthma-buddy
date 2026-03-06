# frozen_string_literal: true

class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access only: [ :show ]

  def show
    user = User.find_by_token_for(:email_verification, params[:token])

    if user.nil?
      redirect_to new_session_path, alert: "Invalid or expired verification link."
    elsif user.email_verified_at.present?
      redirect_to new_session_path, notice: "Email already verified."
    else
      user.update!(email_verified_at: Time.current)
      redirect_to new_session_path, notice: "Email verified! You can now sign in."
    end
  end
end
