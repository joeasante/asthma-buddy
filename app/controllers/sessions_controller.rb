# frozen_string_literal: true

class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    respond_to do |format|
      format.html { redirect_to new_session_path, alert: "Try again later." }
      format.json { render json: { error: "Too many requests. Try again later." }, status: :too_many_requests }
    end
  }

  def new
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))

    unless user
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

    start_new_session_for user
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
