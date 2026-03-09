# frozen_string_literal: true

class SettingsController < ApplicationController
  def show
    redirect_to profile_path, status: :moved_permanently
  end

  def update_personal_best
    respond_to do |format|
      format.html { redirect_to profile_personal_best_path, status: :temporary_redirect, allow_other_host: false }
      format.json do
        render json: {
          error: "This endpoint has moved permanently.",
          new_url: profile_personal_best_url
        }, status: :gone
      end
    end
  end
end
