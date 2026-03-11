# frozen_string_literal: true

class PeakFlowReadingsController < ApplicationController
  ALLOWED_PRESETS = %w[7 30 90 all custom].freeze

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

  before_action :set_has_personal_best, only: %i[new create edit]
  before_action :set_peak_flow_reading, only: %i[show edit update destroy]

  def show
    @personal_best = PersonalBestRecord.current_for(Current.user)
    pb_value = @personal_best&.value
    @zone_percentage = pb_value && @peak_flow_reading.zone ? ((@peak_flow_reading.value.to_f / pb_value) * 100).round : nil
    respond_to do |format|
      format.html
      format.json { render json: peak_flow_reading_json(@peak_flow_reading) }
    end
  end

  def new
    @peak_flow_reading = Current.user.peak_flow_readings.new(
      recorded_at: Time.current.change(sec: 0),
      time_of_day: Time.current.hour < 13 ? :morning : :evening
    )
  end

  def index
    @active_preset = ALLOWED_PRESETS.include?(params[:preset]) ? params[:preset] : "30"

    if params[:start_date].present? || params[:end_date].present?
      @start_date = parse_date_param(:start_date)
      @end_date   = parse_date_param(:end_date)
    else
      @end_date = nil
      @start_date = case @active_preset
      when "7"  then Date.current - 7.days
      when "30" then Date.current - 30.days
      when "90" then Date.current - 90.days
      else nil
      end
    end

    @active_zone = %w[green yellow red].include?(params[:zone]) ? params[:zone] : nil

    base_relation = Current.user.peak_flow_readings
                           .chronological
                           .in_date_range(@start_date, @end_date)
    base_relation = base_relation.where(zone: @active_zone) if @active_zone.present?
    @current_personal_best = PersonalBestRecord.current_for(Current.user)

    total = base_relation.count
    @peak_flow_readings, @total_pages, @current_page = base_relation.paginate(
      page: params[:page], total: total
    )

    # Header eyebrow queries — skipped on turbo-frame requests since the header
    # sits outside the frame and its content is discarded anyway.
    unless turbo_frame_request?
      @header_last_reading = Current.user.peak_flow_readings.chronological.first
      @header_month_count  = Current.user.peak_flow_readings
                                     .where(recorded_at: Date.current.beginning_of_month..)
                                     .count
    end

    respond_to do |format|
      format.html do
        # One entry per day with separate morning/evening values for the two-line chart.
        @chart_data = base_relation
          .reorder(recorded_at: :asc)
          .limit(500)
          .pluck(:recorded_at, :value, :zone, :time_of_day)
          .map { |ts, v, z, tod| { date: ts.to_date.to_s, value: v, zone: z, time_of_day: tod || (ts.hour < 13 ? "morning" : "evening") } }
          .group_by { |d| d[:date] }
          .map do |date, readings|
            am = readings.select { |r| r[:time_of_day] == "morning" }.max_by { |r| r[:value] }
            pm = readings.select { |r| r[:time_of_day] == "evening" }.max_by { |r| r[:value] }
            { date: date, morning: am&.dig(:value), morning_zone: am&.dig(:zone), evening: pm&.dig(:value), evening_zone: pm&.dig(:zone) }
          end
          .sort_by { |d| d[:date] }

        @period_count = total
        @period_avg   = base_relation.average(:value)&.round
        @period_best  = base_relation.maximum(:value)

        pb_value = @current_personal_best&.value
        @period_avg_pct  = pb_value && @period_avg  ? ((@period_avg.to_f  / pb_value) * 100).round : nil
        @period_best_pct = pb_value && @period_best ? ((@period_best.to_f / pb_value) * 100).round : nil

        @grouped_readings = @peak_flow_readings
          .group_by { |r| r.recorded_at.to_date }

        chart_end = @end_date || Date.current
        events_rel = Current.user.health_events
          .where(recorded_at: ..chart_end.end_of_day)
          .where.not(event_type: HealthEvent::POINT_IN_TIME_TYPES)
        events_rel = events_rel.where(recorded_at: @start_date.beginning_of_day..) if @start_date
        @health_event_markers = events_rel.order(recorded_at: :asc).map(&:to_chart_marker)
      end
      format.json do
        render json: {
          readings:        @peak_flow_readings.map { |r| peak_flow_reading_json(r) },
          current_page:    @current_page,
          total_pages:     @total_pages,
          per_page:        25,
          applied_filters: {
            preset:     @active_preset,
            start_date: @start_date&.to_s,
            end_date:   @end_date&.to_s
          }
        }
      end
    end
  end

  def create
    @peak_flow_reading = Current.user.peak_flow_readings.new(peak_flow_reading_params)

    if @peak_flow_reading.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to peak_flow_readings_path, notice: helpers.zone_flash_message_text(@peak_flow_reading) }
        format.json { render json: peak_flow_reading_json(@peak_flow_reading), status: :created }
      end
    else
      @duplicate_reading = @peak_flow_reading.duplicate_session_reading
      respond_to do |format|
        format.turbo_stream { render :form_error, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
        format.json do
          json_response = { errors: @peak_flow_reading.errors.full_messages }
          if @peak_flow_reading.duplicate_session_reading.present?
            json_response[:duplicate_reading] = peak_flow_reading_json(@peak_flow_reading.duplicate_session_reading)
          end
          render json: json_response, status: :unprocessable_entity
        end
      end
    end
  end

  def edit
    # @peak_flow_reading and @has_personal_best set by before_actions
  end

  def update
    if @peak_flow_reading.update(peak_flow_reading_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to peak_flow_reading_path(@peak_flow_reading), notice: "Reading updated." }
        format.json { render json: peak_flow_reading_json(@peak_flow_reading) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :update_error, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @peak_flow_reading.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  rescue ActiveRecord::RecordNotUnique
    @peak_flow_reading.errors.add(:base, "You already have a #{@peak_flow_reading.time_of_day} reading for that date")
    respond_to do |format|
      format.turbo_stream { render :update_error, status: :unprocessable_entity }
      format.html { render :edit, status: :unprocessable_entity }
      format.json { render json: { errors: @peak_flow_reading.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  def destroy
    @peak_flow_reading.destroy
    respond_to do |format|
      format.turbo_stream do
        @header_last_reading = Current.user.peak_flow_readings.chronological.first
        @header_month_count  = Current.user.peak_flow_readings
                                       .where(recorded_at: Date.current.beginning_of_month..)
                                       .count
        render :destroy
      end
      format.html { redirect_to peak_flow_readings_path, notice: "Reading deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_has_personal_best
    best = PersonalBestRecord.current_for(Current.user)
    @has_personal_best    = best.present?
    @personal_best_value  = best&.value.to_i
  end

  def set_peak_flow_reading
    @peak_flow_reading = Current.user.peak_flow_readings.find(params[:id])
  end

  def parse_date_param(key)
    value = params[key]
    return nil if value.blank?
    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def peak_flow_reading_params
    params.require(:peak_flow_reading).permit(:value, :recorded_at, :time_of_day)
  end

  def peak_flow_reading_json(reading)
    {
      id:          reading.id,
      value:       reading.value,
      recorded_at: reading.recorded_at,
      zone:        reading.zone
    }
  end
end
