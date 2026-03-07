# frozen_string_literal: true

class PeakFlowReadingsController < ApplicationController
  rate_limit to: 60, within: 1.minute, only: :create

  def new
    @peak_flow_reading = Current.user.peak_flow_readings.new(
      recorded_at: Time.current.change(sec: 0)
    )
    @has_personal_best = PersonalBestRecord.current_for(Current.user).present?
  end

  def create
    @peak_flow_reading = Current.user.peak_flow_readings.new(peak_flow_reading_params)

    if @peak_flow_reading.save
      @flash_message = zone_flash_message(@peak_flow_reading)
      @has_personal_best = PersonalBestRecord.current_for(Current.user).present?
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to new_peak_flow_reading_path, notice: @flash_message }
        format.json { render json: peak_flow_reading_json(@peak_flow_reading), status: :created }
      end
    else
      @has_personal_best = PersonalBestRecord.current_for(Current.user).present?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "peak_flow_reading_form",
            partial: "form",
            locals: { peak_flow_reading: @peak_flow_reading, has_personal_best: @has_personal_best }
          ), status: :unprocessable_entity
        end
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @peak_flow_reading.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def peak_flow_reading_params
    params.require(:peak_flow_reading).permit(:value, :recorded_at)
  end

  def zone_flash_message(reading)
    if reading.zone.nil?
      "Reading saved — set your personal best to see your zone."
    else
      "Reading saved — #{reading.zone.capitalize} Zone (#{reading.zone_percentage}% of personal best)."
    end
  end

  def peak_flow_reading_json(reading)
    {
      id: reading.id,
      value: reading.value,
      recorded_at: reading.recorded_at,
      zone: reading.zone,
      zone_percentage: reading.zone_percentage,
      personal_best_at_reading_time: reading.personal_best_at_reading_time,
      created_at: reading.created_at
    }
  end
end
