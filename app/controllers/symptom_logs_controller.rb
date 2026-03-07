# frozen_string_literal: true

class SymptomLogsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_symptom_log, only: %i[ edit update destroy ]

  def index
    # Resolve date bounds from preset or custom params
    @active_preset = params[:preset].presence || "all"

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

    base_relation = Current.user.symptom_logs
                           .chronological
                           .in_date_range(@start_date, @end_date)
                           .includes(:rich_text_notes)

    @severity_counts = { mild: 0, moderate: 0, severe: 0 }.merge(base_relation.severity_counts)
    @symptom_logs, @total_pages, @current_page = base_relation.paginate(page: params[:page])

    respond_to do |format|
      format.html { @symptom_log = Current.user.symptom_logs.new(recorded_at: Time.current) }
      format.json { render json: symptom_logs_json(base_relation) }
    end
  end

  def create
    @symptom_log = Current.user.symptom_logs.new(symptom_log_params)

    if @symptom_log.save
      @severity_counts = { mild: 0, moderate: 0, severe: 0 }.merge(
        Current.user.symptom_logs.severity_counts
      )
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to symptom_logs_path, notice: "Symptom logged." }
        format.json { render json: symptom_log_json(@symptom_log), status: :created }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("symptom_log_form", partial: "form", locals: { symptom_log: @symptom_log }), status: :unprocessable_entity }
        format.html do
          @symptom_logs = Current.user.symptom_logs.chronological.includes(:rich_text_notes)
          render :index, status: :unprocessable_entity
        end
        format.json { render json: { errors: @symptom_log.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    # @symptom_log set by before_action
    # Turbo Frame inline editing: renders edit.html.erb into the frame
  end

  def update
    if @symptom_log.update(symptom_log_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to symptom_logs_path, notice: "Symptom updated." }
        format.json { render json: symptom_log_json(@symptom_log) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@symptom_log), partial: "symptom_logs/form", locals: { symptom_log: @symptom_log }), status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @symptom_log.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @symptom_log.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@symptom_log)) }
      format.html { redirect_to symptom_logs_path, notice: "Symptom deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_symptom_log
    @symptom_log = Current.user.symptom_logs.find(params[:id])
  end

  def symptom_log_params
    params.require(:symptom_log).permit(:symptom_type, :severity, :recorded_at, :notes)
  end

  def symptom_log_json(log)
    log.as_json(only: %i[id symptom_type severity recorded_at created_at]).merge(
      notes: log.notes.to_plain_text
    )
  end

  def symptom_logs_json(logs)
    logs.map { |log| symptom_log_json(log) }
  end
end
