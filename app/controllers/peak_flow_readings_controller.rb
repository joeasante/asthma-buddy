# frozen_string_literal: true

class PeakFlowReadingsController < ApplicationController
  include ActionView::RecordIdentifier

  def new
    @peak_flow_reading   = Current.user.peak_flow_readings.new(
      recorded_at: Time.current.change(sec: 0)
    )
    @has_personal_best   = PersonalBestRecord.current_for(Current.user).present?
  end

  def create
    @peak_flow_reading = Current.user.peak_flow_readings.new(peak_flow_reading_params)

    if @peak_flow_reading.save
      @flash_message = zone_flash_message(@peak_flow_reading)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to new_peak_flow_reading_path, notice: @flash_message }
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
        format.html do
          render :new, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def peak_flow_reading_params
    params.require(:peak_flow_reading).permit(:value, :recorded_at)
  end

  def zone_flash_message(reading)
    pb = reading.personal_best_at_reading_time
    if pb.nil?
      "Reading saved — set your personal best to see your zone."
    else
      zone_label = reading.zone.capitalize
      percentage = ((reading.value.to_f / pb) * 100).round
      "Reading saved — #{zone_label} Zone (#{percentage}% of personal best)."
    end
  end
end
