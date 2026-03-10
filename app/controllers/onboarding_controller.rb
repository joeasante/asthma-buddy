# frozen_string_literal: true

class OnboardingController < ApplicationController
  layout "onboarding"
  rate_limit to: 10, within: 1.minute, only: %i[submit_1 submit_2], with: -> {
    respond_to do |format|
      format.html { redirect_to onboarding_step_path(1), alert: "Too many submissions. Try again in a moment." }
      format.json { render json: { error: "Rate limit exceeded. Try again later." }, status: :too_many_requests }
    end
  }
  rate_limit to: 5, within: 1.minute, only: :skip, with: -> {
    respond_to do |format|
      format.html { redirect_to onboarding_step_path(1), alert: "Too many submissions. Try again in a moment." }
      format.json { render json: { error: "Rate limit exceeded. Try again later." }, status: :too_many_requests }
    end
  }
  before_action :redirect_if_onboarding_complete
  before_action :redirect_if_step1_done, only: :show

  def show
    @step = current_step
    if @step == 2
      @medication = Medication.new(
        user: Current.user,
        medication_type: :reliever,
        standard_dose_puffs: 2,
        sick_day_dose_puffs: 4,
        doses_per_day: 2,
        starting_dose_count: 200
      )
    end
  end

  def submit_1
    value = params.dig(:personal_best_record, :value).to_i
    unless value.between?(100, 900)
      @step = 1
      flash.now[:alert] = "Please enter a value between 100 and 900 L/min."
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: { errors: [ "Value must be between 100 and 900 L/min" ] }, status: :unprocessable_entity }
      end
      return
    end

    ApplicationRecord.transaction do
      Current.user.personal_best_records.create!(
        value: value,
        recorded_at: Time.current.change(sec: 0)
      )
      Current.user.update!(onboarding_personal_best_done: true)
    end

    respond_to do |format|
      format.html { redirect_to onboarding_step_path(2) }
      format.json { render json: { onboarding_personal_best_done: true, next_step: 2 }, status: :ok }
    end
  end

  def submit_2
    @medication = Medication.new(medication_params.merge(user: Current.user))
    if @medication.valid?
      ApplicationRecord.transaction do
        @medication.save!
        Current.user.update!(onboarding_medication_done: true)
      end
      respond_to do |format|
        format.html { redirect_to dashboard_path, notice: "Welcome to Asthma Buddy! You're all set." }
        format.json { render json: { onboarding_medication_done: true }, status: :ok }
      end
    else
      @step = 2
      respond_to do |format|
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: { errors: @medication.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def skip
    step = params[:step].to_i
    case step
    when 1
      Current.user.update!(onboarding_personal_best_done: true)
      respond_to do |format|
        format.html { redirect_to onboarding_step_path(2) }
        format.json { render json: { onboarding_personal_best_done: true, next_step: 2 }, status: :ok }
      end
    when 2
      Current.user.update!(onboarding_personal_best_done: true, onboarding_medication_done: true)
      respond_to do |format|
        format.html { redirect_to dashboard_path, notice: "You can complete setup any time from Settings." }
        format.json { render json: { onboarding_personal_best_done: true, onboarding_medication_done: true }, status: :ok }
      end
    end
  end

  private

    def redirect_if_onboarding_complete
      redirect_to dashboard_path if Current.user.onboarding_complete?
    end

    def redirect_if_step1_done
      redirect_to onboarding_step_path(2) if params[:step].to_i == 1 && Current.user.onboarding_personal_best_done?
    end

    def current_step
      step = params[:step].to_i
      step.between?(1, 2) ? step : 1
    end

    def medication_params
      params.require(:medication).permit(
        :name, :medication_type, :standard_dose_puffs,
        :starting_dose_count, :sick_day_dose_puffs, :doses_per_day
      )
    end
end
