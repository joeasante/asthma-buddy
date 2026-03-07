# frozen_string_literal: true

class SymptomLogsController < ApplicationController
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

  private

  def symptom_log_params
    params.require(:symptom_log).permit(:symptom_type, :severity, :recorded_at, :notes)
  end
end
