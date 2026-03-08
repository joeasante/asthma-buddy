# frozen_string_literal: true

module Settings
  class DoseLogsController < ApplicationController
    before_action :set_medication
    before_action :set_dose_log, only: :destroy

    def create
      @dose_log = @medication.dose_logs.new(dose_log_params)
      @dose_log.user = Current.user
      if @dose_log.save
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to settings_medications_path, notice: "Dose logged." }
        end
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("dose_log_form_#{dom_id(@medication)}", partial: "settings/dose_logs/form", locals: { medication: @medication, dose_log: @dose_log }), status: :unprocessable_entity }
          format.html { redirect_to settings_medications_path, alert: "Could not log dose." }
        end
      end
    end

    def destroy
      @dose_log.destroy
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to settings_medications_path, notice: "Dose removed." }
      end
    end

    private

    def set_medication
      @medication = Current.user.medications.find(params[:medication_id])
    end

    def set_dose_log
      @dose_log = @medication.dose_logs.find(params[:id])
    end

    def dose_log_params
      params.require(:dose_log).permit(:puffs, :recorded_at)
    end
  end
end
