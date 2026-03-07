# frozen_string_literal: true

class PeakFlowReadingsController < ApplicationController
  rate_limit to: 10, within: 1.minute, only: :create, with: -> {
    respond_to do |format|
      format.html { redirect_to new_peak_flow_reading_path, alert: "Too many submissions. Try again in a moment." }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("flash-messages") {
          tag.div(id: "flash-messages") {
            tag.p("Too many submissions. Try again in a moment.",
                  role: "alert", class: "flash flash--alert")
          }
        }, status: :too_many_requests
      end
      format.json { render json: { error: "Rate limit exceeded. Try again later." }, status: :too_many_requests }
    end
  }

  before_action :set_has_personal_best, only: %i[new create]

  def new
    @peak_flow_reading = Current.user.peak_flow_readings.new(
      recorded_at: Time.current.change(sec: 0)
    )
  end

  def index
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
    end_date   = params[:end_date].present?   ? Date.parse(params[:end_date])   : Date.current

    @peak_flow_readings = Current.user.peak_flow_readings
      .chronological
      .where(recorded_at: start_date.beginning_of_day..end_date.end_of_day)

    respond_to do |format|
      format.html
      format.json { render json: @peak_flow_readings.map { |r| peak_flow_reading_json(r) } }
    end
  end

  def create
    @peak_flow_reading = Current.user.peak_flow_readings.new(peak_flow_reading_params)

    if @peak_flow_reading.save
      @flash_message = helpers.zone_flash_message(@peak_flow_reading)
      @new_peak_flow_reading = Current.user.peak_flow_readings.new(
        recorded_at: Time.current.change(sec: 0)
      )
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to new_peak_flow_reading_path, notice: helpers.zone_flash_message_text(@peak_flow_reading) }
        format.json { render json: peak_flow_reading_json(@peak_flow_reading), status: :created }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :form_error, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @peak_flow_reading.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_has_personal_best
    @has_personal_best = PersonalBestRecord.exists_for?(Current.user)
  end

  def peak_flow_reading_params
    params.require(:peak_flow_reading).permit(:value, :recorded_at)
  end

  def peak_flow_reading_json(reading)
    {
      id: reading.id,
      value: reading.value,
      recorded_at: reading.recorded_at,
      zone: reading.zone,
      zone_percentage: reading.zone_percentage,
      created_at: reading.created_at
    }
  end
end
