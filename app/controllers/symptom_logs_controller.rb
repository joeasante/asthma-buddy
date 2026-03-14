# frozen_string_literal: true

class SymptomLogsController < ApplicationController
  rate_limit to: 10, within: 1.minute, only: %i[create update], with: -> {
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("flash-messages") {
          tag.div(id: "flash-messages") {
            tag.p("Too many submissions. Try again in a moment.",
                  role: "alert", class: "flash flash--alert")
          }
        }, status: :too_many_requests
      end
      format.html { redirect_to symptom_logs_path, alert: "Too many submissions. Try again in a moment." }
      format.json { render json: { error: "Rate limit exceeded. Try again later." }, status: :too_many_requests }
    end
  }

  before_action :set_symptom_log, only: %i[ show edit update destroy ]

  def show
    authorize @symptom_log
    respond_to do |format|
      format.html
      format.json { render json: symptom_log_json(@symptom_log) }
    end
  end

  def index
    # Resolve date bounds from preset or custom params
    @active_preset        = params[:preset].presence || "all"
    @active_severity      = params[:severity].presence
    @active_symptom_type  = params[:symptom_type].presence

    if params[:start_date].present? || params[:end_date].present?
      @start_date = params[:start_date].present? ? (Date.parse(params[:start_date]) rescue nil) : nil
      @end_date   = params[:end_date].present?   ? (Date.parse(params[:end_date])   rescue nil) : nil
    else
      @end_date = nil
      @start_date = case @active_preset
      when "7"  then Date.current - 7.days
      when "30" then Date.current - 30.days
      when "90" then Date.current - 90.days
      else nil
      end
    end

    authorize SymptomLog
    base_relation = Current.user.symptom_logs
                           .chronological
                           .in_date_range(@start_date, @end_date)
                           .includes(:rich_text_notes)

    base_relation = base_relation.where(symptom_type: @active_symptom_type) if @active_symptom_type.present?

    # Compute severity counts before applying the severity filter so the trend bar
    # always shows the full distribution across the date range.
    @severity_counts = { mild: 0, moderate: 0, severe: 0 }.merge(base_relation.severity_counts)
    base_relation = base_relation.where(severity: @active_severity) if @active_severity.present?

    @symptom_logs, @total_pages, @current_page = base_relation.paginate(page: params[:page])

    # Header eyebrow: most recent log (all-time) + this month's count
    all_logs = Current.user.symptom_logs.chronological
    @header_last_log    = all_logs.first
    @header_month_count = all_logs.where(recorded_at: Date.current.beginning_of_month..).count

    respond_to do |format|
      format.html do
        @chart_data = build_chart_data(base_relation)
      end
      format.json do
        render json: {
          symptom_logs:    @symptom_logs.map { |log| symptom_log_json(log) },
          current_page:    @current_page,
          total_pages:     @total_pages,
          per_page:        25,
          applied_filters: {
            preset:        @active_preset,
            severity:      @active_severity,
            symptom_type:  @active_symptom_type,
            start_date:    @start_date&.to_s,
            end_date:      @end_date&.to_s
          }
        }
      end
    end
  end

  def new
    @symptom_log = Current.user.symptom_logs.new(recorded_at: Time.current.change(sec: 0))
    authorize @symptom_log
  end

  def create
    @symptom_log = Current.user.symptom_logs.new(symptom_log_params)
    authorize @symptom_log

    if @symptom_log.save
      @severity_counts = { mild: 0, moderate: 0, severe: 0 }.merge(
        Current.user.symptom_logs.severity_counts
      )
      all_logs = Current.user.symptom_logs.chronological
      @header_last_log    = all_logs.first
      @header_month_count = all_logs.where(recorded_at: Date.current.beginning_of_month..).count
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to symptom_logs_path, notice: "Symptom logged." }
        format.json { render json: symptom_log_json(@symptom_log), status: :created }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("symptom_log_form", partial: "form", locals: { symptom_log: @symptom_log }), status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @symptom_log.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize @symptom_log
  end

  def update
    authorize @symptom_log
    if @symptom_log.update(symptom_log_params)
      @severity_counts = { mild: 0, moderate: 0, severe: 0 }.merge(
        Current.user.symptom_logs.severity_counts
      )
      all_logs = Current.user.symptom_logs.chronological
      @header_last_log    = all_logs.first
      @header_month_count = all_logs.where(recorded_at: Date.current.beginning_of_month..).count
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to symptom_logs_path, notice: "Symptom updated." }
        format.json { render json: symptom_log_json(@symptom_log) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@symptom_log), partial: "form", locals: { symptom_log: @symptom_log }), status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @symptom_log.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @symptom_log
    @symptom_log.destroy
    @severity_counts = { mild: 0, moderate: 0, severe: 0 }.merge(
      Current.user.symptom_logs.severity_counts
    )
    all_logs = Current.user.symptom_logs.chronological
    @header_last_log    = all_logs.first
    @header_month_count = all_logs.where(recorded_at: Date.current.beginning_of_month..).count
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to symptom_logs_path, notice: "Symptom deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_symptom_log
    @symptom_log = Current.user.symptom_logs.find(params[:id])
  end

  def symptom_log_params
    params.require(:symptom_log).permit(:symptom_type, :severity, :recorded_at, :notes, triggers: [])
  end

  def build_chart_data(relation)
    counts = relation.group("DATE(recorded_at)", :severity).count
    grouped = counts.each_with_object({}) do |((date, severity), count), h|
      key = date.to_s
      h[key] ||= { date: key, mild: 0, moderate: 0, severe: 0 }
      h[key][severity.to_sym] = count
    end
    grouped.values.sort_by { |d| d[:date] }
  end

  def symptom_log_json(log)
    log.as_json(only: %i[id symptom_type severity recorded_at created_at]).merge(
      notes:    log.notes.to_plain_text,
      triggers: log.triggers
    )
  end
end
