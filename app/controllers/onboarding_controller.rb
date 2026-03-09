# frozen_string_literal: true

class OnboardingController < ApplicationController
  layout "onboarding"

  def show
    @step = params[:step].to_i
    redirect_to onboarding_step_path(1) unless @step.between?(1, 3)

    if @step == 2
      @medication = Current.user.medications.new(
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
      redirect_to onboarding_step_path(2)
    else
      @step = 1
      flash.now[:alert] = "Please enter a value between 100 and 900 L/min."
      render :show, status: :unprocessable_entity
    end
  end

  def submit_2
    @medication = Current.user.medications.new(medication_params)
    if @medication.save
      redirect_to onboarding_step_path(3)
    else
      @step = 2
      render :show, status: :unprocessable_entity
    end
  end

  def skip
    step = params[:step].to_i
    if step >= 3
      redirect_to dashboard_path, notice: "Welcome to Asthma Buddy! You're all set."
    else
      redirect_to onboarding_step_path(step + 1)
    end
  end

  private

    def medication_params
      params.require(:medication).permit(
        :name, :medication_type, :standard_dose_puffs,
        :starting_dose_count, :sick_day_dose_puffs, :doses_per_day
      )
    end
end
