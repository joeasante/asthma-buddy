# frozen_string_literal: true

class AccountsController < ApplicationController
  def destroy
    if params[:confirmation] == "DELETE"
      Current.user.destroy
      reset_session
      redirect_to root_path, notice: "Your account and all associated data have been permanently deleted."
    else
      redirect_to settings_path, alert: "Account not deleted. You must type DELETE exactly to confirm."
    end
  end
end
