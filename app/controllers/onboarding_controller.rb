# frozen_string_literal: true

class OnboardingController < ApplicationController
  layout "onboarding"
  before_action :redirect_if_onboarding_complete

  def show
    @step = current_step
    case @step
    when 1
      # nothing — Step 1 only needs the personal best value field
    when 2
      @medication = Medication.new(
        user: Current.user,
        medication_type: :reliever,
        standard_dose_puffs: 2,
        sick_day_dose_puffs: 4,
        doses_per_day: 2
      )
    end
  end

  def submit_1
    value = params.dig(:personal_best_record, :value).to_i
    if value.between?(100, 900)
      Current.user.personal_best_records.create!(
        value: value,
        recorded_at: Time.current.change(sec: 0)
      )
      Current.user.update!(onboarding_personal_best_done: true)
      redirect_to onboarding_step_path(2)
    else
      @step = 1
      flash.now[:alert] = "Please enter a value between 100 and 900 L/min."
      render :show, status: :unprocessable_entity
    end
  end

  def submit_2
    @medication = Medication.new(medication_params.merge(user: Current.user))
    if @medication.save
      Current.user.update!(onboarding_medication_done: true)
      redirect_to dashboard_path, notice: "Welcome to Asthma Buddy! You're all set."
    else
      @step = 2
      render :show, status: :unprocessable_entity
    end
  end

  def skip
    step = params[:step].to_i
    case step
    when 1
      Current.user.update!(onboarding_personal_best_done: true)
      redirect_to onboarding_step_path(2)
    when 2
      Current.user.update!(onboarding_medication_done: true)
      redirect_to dashboard_path, notice: "You can complete setup any time from Settings."
    else
      redirect_to dashboard_path
    end
  end

  private

    def redirect_if_onboarding_complete
      if Current.user.onboarding_personal_best_done? && Current.user.onboarding_medication_done?
        redirect_to dashboard_path
      end
    end

    def current_step
      step = params[:step].to_i
      # If Step 1 already done, go to step 2; if both done, redirect_if_onboarding_complete handles it
      if step == 1 && Current.user.onboarding_personal_best_done?
        redirect_to onboarding_step_path(2) and return 2
      end
      step.between?(1, 2) ? step : (redirect_to(onboarding_step_path(1)) and return 1)
    end

    def medication_params
      params.require(:medication).permit(
        :name, :medication_type, :standard_dose_puffs,
        :starting_dose_count, :sick_day_dose_puffs, :doses_per_day
      )
    end
end
