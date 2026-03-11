# frozen_string_literal: true

class HealthEventsController < ApplicationController
  before_action :set_health_event, only: %i[show edit update destroy]
  rate_limit to: 10, within: 1.minute, only: %i[create update destroy]

  def show
    if @health_event.illness?
      illness_start = @health_event.recorded_at.beginning_of_day
      illness_end   = (@health_event.ended_at || Time.current).end_of_day
      @illness_symptom_logs = Current.user.symptom_logs
        .in_date_range(illness_start, illness_end)
        .chronological
        .includes(:rich_text_notes)
    end

    respond_to do |format|
      format.html
      format.json { render json: health_event_json(@health_event) }
    end
  end

  def index
    events = Current.user.health_events.includes(:rich_text_notes).recent_first
    @grouped_events = events.group_by { |e| e.recorded_at.beginning_of_month }
    @header_event_count = @grouped_events.values.sum(&:length)
    respond_to do |format|
      format.html
      format.json { render json: events.map { |e| health_event_json(e) } }
    end
  end

  def new
    @health_event = HealthEvent.new(recorded_at: Time.current.change(sec: 0))
  end

  def create
    @health_event = HealthEvent.new(health_event_params.merge(user: Current.user))

    if @health_event.save
      respond_to do |format|
        format.html { redirect_to health_events_path, notice: "Medical event recorded." }
        format.json { render json: health_event_json(@health_event), status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @health_event.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @health_event.update(health_event_params)
      respond_to do |format|
        format.html { redirect_to health_events_path, notice: "Medical event updated." }
        format.json { render json: health_event_json(@health_event) }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @health_event.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @health_event.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to health_events_path, notice: "Medical event deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_health_event
    @health_event = Current.user.health_events.find(params[:id])
  end

  def health_event_params
    params.require(:health_event).permit(:event_type, :recorded_at, :ended_at, :notes)
  end

  def health_event_json(event)
    data = event.as_json(only: %i[id event_type recorded_at ended_at created_at]).merge(
      event_type_label: event.event_type_label,
      ongoing: event.ongoing?,
      formatted_duration: event.formatted_duration,
      notes: event.notes.to_plain_text
    )
    if event.illness?
      illness_end = event.ended_at || Time.current
      symptom_logs = Current.user.symptom_logs
        .where(recorded_at: event.recorded_at.beginning_of_day..illness_end.end_of_day)
        .order(recorded_at: :desc)
      data[:illness_symptom_logs] = symptom_logs.map do |sl|
        { id: sl.id, recorded_at: sl.recorded_at.iso8601, severity: sl.severity,
          notes: sl.notes&.to_plain_text }
      end
    end
    data
  end
end
