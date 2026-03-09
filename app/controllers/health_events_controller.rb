# frozen_string_literal: true

class HealthEventsController < ApplicationController
  before_action :require_authentication
  before_action :set_health_event, only: %i[edit update destroy]
  rate_limit to: 10, within: 1.minute, only: %i[create update destroy]

  def index
    events = Current.user.health_events.includes(:rich_text_notes).recent_first
    @grouped_events = events.group_by { |e| e.recorded_at.beginning_of_month }
    @header_event_count = @grouped_events.values.sum(&:length)
  end

  def new
    @health_event = HealthEvent.new(recorded_at: Time.current.change(sec: 0))
  end

  def create
    @health_event = HealthEvent.new(health_event_params.merge(user: Current.user))

    if @health_event.save
      redirect_to health_events_path, notice: "Medical event recorded."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @health_event.update(health_event_params)
      redirect_to health_events_path, notice: "Medical event updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @health_event.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to health_events_path, notice: "Medical event deleted." }
    end
  end

  private

  def set_health_event
    @health_event = Current.user.health_events.find(params[:id])
  end

  def health_event_params
    params.require(:health_event).permit(:event_type, :recorded_at, :ended_at, :notes)
  end
end
