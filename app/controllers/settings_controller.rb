# frozen_string_literal: true

class SettingsController < ApplicationController
  def show
    authorize :settings, :show?
    respond_to do |format|
      format.html
      format.json do
        render json: {
          profile: {
            full_name:  Current.user.full_name,
            email:      Current.user.email_address,
            avatar_url: Current.user.avatar.attached? ? url_for(Current.user.avatar) : nil
          }
        }
      end
    end
  end
end
