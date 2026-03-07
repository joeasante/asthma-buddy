# frozen_string_literal: true

class SymptomLogsController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :set_symptom_log, only: %i[ edit update destroy ]

  def index
    @symptom_log = Current.user.symptom_logs.new(recorded_at: Time.current)
    @symptom_logs = Current.user.symptom_logs.chronological.includes(:rich_text_notes)
  end

  def create
    @symptom_log = Current.user.symptom_logs.new(symptom_log_params)

    if @symptom_log.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to symptom_logs_path, notice: "Symptom logged." }
      end
    else
      @symptom_logs = Current.user.symptom_logs.chronological.includes(:rich_text_notes)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("symptom_log_form", partial: "form", locals: { symptom_log: @symptom_log }), status: :unprocessable_entity }
        format.html { render :index, status: :unprocessable_entity }
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
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@symptom_log), partial: "symptom_logs/form", locals: { symptom_log: @symptom_log }), status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @symptom_log.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@symptom_log)) }
      format.html { redirect_to symptom_logs_path, notice: "Symptom deleted." }
    end
  end

  private

  def set_symptom_log
    @symptom_log = Current.user.symptom_logs.find(params[:id])
  end

  def symptom_log_params
    params.require(:symptom_log).permit(:symptom_type, :severity, :recorded_at, :notes)
  end
end
