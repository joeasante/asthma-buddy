# frozen_string_literal: true

module Settings
  class MedicationsController < ApplicationController
    before_action :set_medication, only: %i[edit update destroy refill]
    before_action :ensure_course_not_archived, only: %i[edit update]

    def index
      all_medications = Current.user.medications.chronological.includes(:dose_logs)
      @visible_medications = all_medications.reject { |m| m.course? && !m.course_active? }
      @archived_courses    = all_medications.select { |m| m.course? && !m.course_active? }

      # Header eyebrow: active medication count (excludes archived courses) + low stock count
      @header_medication_count = @visible_medications.size
      @header_low_stock_count  = @visible_medications.count(&:low_stock?)
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

    def refill
      new_count = refill_params[:starting_dose_count].to_i
      if new_count >= 0 && @medication.update(starting_dose_count: new_count, refilled_at: Time.current)
        flash.now[:notice] = "#{@medication.name} refilled. #{new_count} doses recorded."
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to settings_medications_path, notice: flash.now[:notice] }
        end
      else
        flash.now[:alert] = "Refill count must be 0 or greater."
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("flash-messages", partial: "layouts/flash"), status: :unprocessable_entity }
          format.html { redirect_to settings_medications_path, alert: flash.now[:alert] }
        end
      end
    end

    private

    def set_medication
      @medication = Current.user.medications.find(params[:id])
    end

    def ensure_course_not_archived
      return unless @medication.course? && !@medication.course_active?
      redirect_to settings_medications_path, notice: "Archived courses cannot be edited."
    end

    def medication_params
      params.require(:medication).permit(
        :name,
        :medication_type,
        :standard_dose_puffs,
        :starting_dose_count,
        :sick_day_dose_puffs,
        :doses_per_day,
        :course,
        :starts_on,
        :ends_on
      )
    end

    def refill_params
      params.require(:medication).permit(:starting_dose_count)
    end
  end
end
