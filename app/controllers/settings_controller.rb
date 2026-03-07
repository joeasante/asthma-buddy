# frozen_string_literal: true

class SettingsController < ApplicationController
  def show
    @current_personal_best = PersonalBestRecord.current_for(Current.user)
    @personal_best_record   = Current.user.personal_best_records.new(
      recorded_at: Time.current
    )
  end

  def update_personal_best
    @personal_best_record = Current.user.personal_best_records.new(personal_best_params)

    if @personal_best_record.save
      redirect_to settings_path, notice: "Personal best updated to #{@personal_best_record.value} L/min."
    else
      @current_personal_best = PersonalBestRecord.current_for(Current.user)
      render :show, status: :unprocessable_entity
    end
  end

  private

  def personal_best_params
    params.require(:personal_best_record).permit(:value).merge(recorded_at: Time.current)
  end
end
