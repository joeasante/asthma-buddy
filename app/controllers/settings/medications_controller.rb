# frozen_string_literal: true

class Settings::MedicationsController < Settings::BaseController
  before_action :set_medication, only: %i[edit update destroy refill]
  before_action :ensure_course_not_archived, only: %i[edit update]

  def index
    # Load all at once (single query + eager-load). Partition in Ruby to avoid
    # firing two separate queries with includes. The partition logic mirrors the
    # Medication.active_courses / archived_courses scopes on the model.
    all_medications = Current.user.medications.chronological.includes(:dose_logs)
    @visible_medications = all_medications.reject { |m| m.course? && !m.course_active? }
    @archived_courses    = all_medications.select { |m| m.course? && !m.course_active? }

    # Header eyebrow: active medication count (excludes archived courses) + low stock count
    @header_medication_count = @visible_medications.size
    @header_low_stock_count  = @visible_medications.count(&:low_stock?)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          active_medications: @visible_medications.map { |m| medication_json(m) },
          archived_courses:   @archived_courses.map { |m| medication_json(m) }
        }
      end
    end
  end

  def new
    @medication = Current.user.medications.new
  end

  def create
    @medication = Current.user.medications.new(medication_params)
    if @medication.save
      set_header_eyebrow_vars
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to settings_medications_path, notice: "Medication added." }
        format.json { render json: medication_json(@medication), status: :created }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("medication_form", partial: "settings/medications/form", locals: { medication: @medication }), status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @medication.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
    # @medication set by before_action; renders edit.html.erb into the turbo_frame_tag dom_id(@medication)
  end

  def update
    if @medication.update(medication_params)
      set_header_eyebrow_vars
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to settings_medications_path, notice: "Medication updated." }
        format.json { render json: medication_json(@medication) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@medication), partial: "settings/medications/form", locals: { medication: @medication }), status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @medication.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @medication.destroy
    set_header_eyebrow_vars
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to settings_medications_path, notice: "Medication removed." }
      format.json { head :no_content }
    end
  end

  def refill
    new_count = refill_params[:starting_dose_count].to_i
    if new_count >= 0 && @medication.update(starting_dose_count: new_count, refilled_at: Time.current)
      flash.now[:notice] = "#{@medication.name} refilled. #{new_count} doses recorded."
      set_header_eyebrow_vars
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to settings_medications_path, notice: flash.now[:notice] }
        format.json { render json: medication_json(@medication) }
      end
    else
      flash.now[:alert] = "Refill count must be 0 or greater."
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash-messages", partial: "layouts/flash"), status: :unprocessable_entity }
        format.html { redirect_to settings_medications_path, alert: flash.now[:alert] }
        format.json { render json: { errors: @medication.errors.full_messages }, status: :unprocessable_entity }
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

  def medication_json(med)
    {
      id:                  med.id,
      name:                med.name,
      medication_type:     med.medication_type,
      standard_dose_puffs: med.standard_dose_puffs,
      sick_day_dose_puffs: med.sick_day_dose_puffs,
      starting_dose_count: med.starting_dose_count,
      doses_per_day:       med.doses_per_day,
      course:              med.course?,
      starts_on:           med.starts_on,
      ends_on:             med.ends_on,
      course_active:       med.course? ? med.course_active? : nil,
      remaining_doses:     med.remaining_doses,
      low_stock:           med.low_stock?,
      created_at:          med.created_at
    }
  end
end
