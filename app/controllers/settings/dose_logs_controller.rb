# frozen_string_literal: true

class Settings::DoseLogsController < Settings::BaseController
  self._skip_pundit = false
  before_action :set_medication
  before_action :set_dose_log, only: :destroy

  def index
    authorize @medication, :show?
    dose_logs = @medication.dose_logs.chronological
    if params[:since].present?
      since_date = begin
        Date.parse(params[:since])
      rescue ArgumentError, TypeError
        Date.current
      end
      dose_logs = dose_logs.where("recorded_at >= ?", since_date)
    end
    respond_to do |format|
      format.json do
        render json: {
          dose_logs:     dose_logs.map { |dl| dose_log_json(dl) },
          total:         dose_logs.size,
          medication_id: @medication.id
        }
      end
    end
  end

  def create
    @dose_log = @medication.dose_logs.new(dose_log_params)
    @dose_log.user = Current.user
    authorize @dose_log
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
    authorize @dose_log
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
