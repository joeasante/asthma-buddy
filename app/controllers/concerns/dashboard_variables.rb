# frozen_string_literal: true

# Shared query logic for the dashboard Turbo Stream variables.
# Included in both DashboardController and Settings::BaseController so that
# dose log actions that stream back to the dashboard view can reload the same data.
# When DashboardController#index query logic changes, update this concern instead.
module DashboardVariables
  extend ActiveSupport::Concern

  def self.dashboard_cache_key(user_id, date = Date.current)
    DashboardCacheInvalidatable.dashboard_cache_key(user_id, date)
  end

  private

  def set_dashboard_vars
    user  = Current.user
    today = Date.current

    cached = Rails.cache.fetch(
      DashboardVariables.dashboard_cache_key(user.id, today),
      expires_in: 5.minutes,
      race_condition_ttl: 10.seconds
    ) do
      preventer_adherence = user.medications
        .where(medication_type: :preventer, course: false)
        .where.not(doses_per_day: nil)
        .includes(:dose_logs)
        .map do |m|
          today_logs = m.dose_logs.select { |dl| dl.recorded_at.to_date == today }
          result = AdherenceCalculator.call(m, today, preloaded_logs: today_logs)
          {
            id:                  m.id,
            name:                m.name,
            standard_dose_puffs: m.standard_dose_puffs,
            sick_day_dose_puffs: m.sick_day_dose_puffs,
            taken:               result.taken,
            scheduled:           result.scheduled,
            status:              result.status
          }
        end
      reliever_medications = user.medications
        .where(medication_type: :reliever, course: false)
        .includes(:dose_logs)
        .chronological
        .map do |m|
          {
            id:                  m.id,
            name:                m.name,
            standard_dose_puffs: m.standard_dose_puffs,
            sick_day_dose_puffs: m.sick_day_dose_puffs,
            today_puffs:         m.dose_logs.select { |dl| dl.recorded_at.to_date == today }.sum(&:puffs)
          }
        end
      illness = user.health_events
        .where(event_type: :illness, ended_at: nil)
        .order(recorded_at: :desc)
        .first
      active_illness = illness && { id: illness.id, recorded_at: illness.recorded_at }

      { preventer_adherence: preventer_adherence, reliever_medications: reliever_medications, active_illness: active_illness }
    end

    @preventer_adherence  = cached[:preventer_adherence]
    @reliever_medications = cached[:reliever_medications]
    @active_illness       = cached[:active_illness]
  end
end
