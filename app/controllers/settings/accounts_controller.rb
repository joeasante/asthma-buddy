# frozen_string_literal: true

module Settings
  class AccountsController < ApplicationController
    rate_limit to: 3, within: 10.minutes, only: :destroy, with: -> {
      respond_to do |format|
        format.html { redirect_to settings_path, alert: "Too many deletion attempts. Please try again later." }
        format.json { render json: { error: "Too many deletion attempts." }, status: :too_many_requests }
      end
    }

    def destroy
      if params[:confirmation] == "DELETE"
        user = Current.user
        terminate_session
        user.destroy
        respond_to do |format|
          format.html { redirect_to root_path, notice: "Your account and all associated data have been permanently deleted." }
          format.json { head :no_content }
        end
      else
        respond_to do |format|
          format.html { redirect_to settings_path, alert: "Account not deleted. You must type DELETE exactly to confirm." }
          format.json { render json: { error: "Confirmation required. Send confirmation=DELETE." }, status: :unprocessable_entity }
        end
      end
    end
  end
end
