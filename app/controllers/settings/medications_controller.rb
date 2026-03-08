# frozen_string_literal: true

module Settings
  class MedicationsController < ApplicationController
    before_action :set_medication, only: %i[edit update destroy]

    def index
      @medications = Current.user.medications.chronological
    end

    def new
      @medication = Current.user.medications.new
    end

    def create
      @medication = Current.user.medications.new(medication_params)
      if @medication.save
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to settings_medications_path, notice: "Medication added." }
        end
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("medication_form", partial: "settings/medications/form", locals: { medication: @medication }), status: :unprocessable_entity }
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      # @medication set by before_action; renders edit.html.erb into the turbo_frame_tag dom_id(@medication)
    end

    def update
      if @medication.update(medication_params)
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to settings_medications_path, notice: "Medication updated." }
        end
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@medication), partial: "settings/medications/form", locals: { medication: @medication }), status: :unprocessable_entity }
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @medication.destroy
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to settings_medications_path, notice: "Medication removed." }
      end
    end

    private

    def set_medication
      @medication = Current.user.medications.find(params[:id])
    end

    def medication_params
      params.require(:medication).permit(
        :name,
        :medication_type,
        :standard_dose_puffs,
        :starting_dose_count,
        :sick_day_dose_puffs,
        :doses_per_day
      )
    end
  end
end
