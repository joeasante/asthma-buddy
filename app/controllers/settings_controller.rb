# frozen_string_literal: true

class SettingsController < ApplicationController
  rate_limit to: 10, within: 1.minute, only: :update_personal_best

  def show
    @current_personal_best = PersonalBestRecord.current_for(Current.user)
    @personal_best_record   = Current.user.personal_best_records.new(
      recorded_at: Time.current
    )
    respond_to do |format|
      format.html
      format.json do
        render json: {
          current_personal_best: personal_best_json(@current_personal_best),
          valid_range: { min: 100, max: 900 }
        }
      end
    end
  end

  def update_personal_best
    @personal_best_record = Current.user.personal_best_records.new(personal_best_params)

    if @personal_best_record.save
      respond_to do |format|
        format.html { redirect_to settings_path, notice: "Personal best updated to #{@personal_best_record.value} L/min." }
        format.json { render json: personal_best_json(@personal_best_record), status: :created }
      end
    else
      @current_personal_best = PersonalBestRecord.current_for(Current.user)
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: { errors: @personal_best_record.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def personal_best_params
    params.require(:personal_best_record).permit(:value).merge(recorded_at: Time.current)
  end

  def personal_best_json(record)
    return nil if record.nil? || record.new_record?
    { id: record.id, value: record.value, recorded_at: record.recorded_at }
  end
end
