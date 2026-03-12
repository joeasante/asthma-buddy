# frozen_string_literal: true

# Shared query logic for the dashboard Turbo Stream variables.
# Included in both DashboardController and Settings::BaseController so that
# dose log actions that stream back to the dashboard view can reload the same data.
# When DashboardController#index query logic changes, update this concern instead.
module DashboardVariables
  extend ActiveSupport::Concern

  private

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
end
