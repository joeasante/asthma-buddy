# frozen_string_literal: true

class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    respond_to do |format|
      format.html { redirect_to new_password_path, alert: "Try again later." }
      format.json { render json: { error: "Too many requests. Try again later." }, status: :too_many_requests }
    end
  }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    respond_to do |format|
      format.html { redirect_to new_session_path, notice: "Password reset instructions sent (if user with that email address exists)." }
      format.json { render json: { message: "Password reset instructions sent (if user with that email address exists)." }, status: :ok }
    end
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      respond_to do |format|
        format.html { redirect_to new_session_path, notice: "Password has been reset." }
        format.json { render json: { message: "Password has been reset." }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to edit_password_path(params[:token]), alert: "Passwords did not match." }
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

    def set_user_by_token
      @user = User.find_by_token_for(:password_reset, params[:token])
      return if @user

      respond_to do |format|
        format.html { redirect_to new_password_path, alert: "Password reset link is invalid or has expired." }
        format.json { render json: { error: "Password reset link is invalid or has expired." }, status: :not_found }
      end
    end
end
