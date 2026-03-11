# frozen_string_literal: true

module Settings
  class DoseLogsController < ApplicationController
    before_action :set_medication
    before_action :set_dose_log, only: :destroy

    def create
      @dose_log = @medication.dose_logs.new(dose_log_params)
      @dose_log.user = Current.user
      if @dose_log.save
        flash.now[:notice] = "Dose logged."
        set_header_eyebrow_vars
        set_dashboard_vars
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to settings_medications_path, notice: "Dose logged." }
          format.json { render json: dose_log_json(@dose_log), status: :created }
        end
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("dose_log_form_#{dom_id(@medication)}", partial: "settings/dose_logs/form", locals: { medication: @medication, dose_log: @dose_log }), status: :unprocessable_entity }
          format.html { redirect_to settings_medications_path, alert: "Could not log dose." }
          format.json { render json: { errors: @dose_log.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @dose_log.destroy
      flash.now[:notice] = "Dose removed."
      set_header_eyebrow_vars
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to settings_medications_path, notice: "Dose removed." }
        format.json { head :no_content }
      end
    end

    private

    def set_header_eyebrow_vars
      all_meds = Current.user.medications.chronological.includes(:dose_logs)
      visible  = all_meds.reject { |m| m.course? && !m.course_active? }
      @header_medication_count = visible.size
      @header_low_stock_count  = visible.count(&:low_stock?)
    end

    def set_dashboard_vars
      user  = Current.user
      today = Date.current
      @preventer_adherence = user.medications
        .where(medication_type: :preventer)
        .where(course: false)
        .includes(:dose_logs)
        .select { |m| m.doses_per_day.present? }
        .map { |m| { medication: m, result: AdherenceCalculator.call(m, today) } }
      @reliever_medications = user.medications
        .where(medication_type: :reliever)
        .where(course: false)
        .includes(:dose_logs)
        .chronological
        .to_a
      @active_illness = user.health_events
        .where(event_type: :illness)
        .where(ended_at: nil)
        .order(recorded_at: :desc)
        .first
    end

    def set_medication
      @medication = Current.user.medications.find(params[:medication_id])
    end

    def set_dose_log
      @dose_log = @medication.dose_logs.find(params[:id])
    end

    def dose_log_params
      permitted = params.require(:dose_log).permit(:puffs, :recorded_at)
      permitted[:recorded_at] = Time.current if permitted[:recorded_at].blank?
      permitted
    end

    def dose_log_json(dose_log)
      {
        id:            dose_log.id,
        medication_id: dose_log.medication_id,
        puffs:         dose_log.puffs,
        recorded_at:   dose_log.recorded_at,
        created_at:    dose_log.created_at
      }
    end
  end
end
