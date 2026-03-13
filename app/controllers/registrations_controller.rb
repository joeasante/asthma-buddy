# frozen_string_literal: true

class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  skip_before_action :check_session_freshness, only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    respond_to do |format|
      format.html { redirect_to new_registration_path, alert: "Try again later." }
      format.json { render json: { error: "Too many requests. Try again later." }, status: :too_many_requests }
    end
  }

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    if @user.save
      UserMailer.email_verification(@user).deliver_later
      respond_to do |format|
        format.html { redirect_to new_session_path, notice: "Account created. Please check your email to verify your account." }
        format.json { render json: { message: "Account created. Check your email to verify." }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

    def registration_params
      params.require(:user).permit(:email_address, :password, :password_confirmation)
    end
end
