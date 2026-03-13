# frozen_string_literal: true

# Shared query logic for the dashboard Turbo Stream variables.
# Included in both DashboardController and Settings::BaseController so that
# dose log actions that stream back to the dashboard view can reload the same data.
# When DashboardController#index query logic changes, update this concern instead.
module DashboardVariables
  extend ActiveSupport::Concern

  def self.dashboard_cache_key(user_id, date = Date.current)
    "dashboard_vars/#{user_id}/#{date}"
  end

  private

  def set_dashboard_vars
    user  = Current.user
    today = Date.current

    # NOTE: The cache stores full ActiveRecord objects (Medication with preloaded dose_logs,
    # HealthEvent). This keeps the fetch block simple but carries a Marshal/schema-migration
    # caveat: a column rename between cache write and read can produce nil fields on the
    # deserialized objects. The 5-minute TTL and write-triggered invalidation callbacks on
    # DoseLog, HealthEvent, and Medication keep the risk window small. A future refactor
    # should replace AR objects with plain scalar hashes (see todo 338).
    cached = Rails.cache.fetch(
      DashboardVariables.dashboard_cache_key(user.id, today),
      expires_in: 5.minutes,
      race_condition_ttl: 10.seconds
    ) do
      preventer_adherence = user.medications
        .where(medication_type: :preventer)
        .where(course: false)
        .includes(:dose_logs)
        .select { |m| m.doses_per_day.present? }
        .map { |m| { medication: m, result: AdherenceCalculator.call(m, today) } }
      reliever_medications = user.medications
        .where(medication_type: :reliever)
        .where(course: false)
        .includes(:dose_logs)
        .chronological
        .to_a
      active_illness = user.health_events
        .where(event_type: :illness)
        .where(ended_at: nil)
        .order(recorded_at: :desc)
        .first

      { preventer_adherence: preventer_adherence, reliever_medications: reliever_medications, active_illness: active_illness }
    end

    @preventer_adherence  = cached[:preventer_adherence]
    @reliever_medications = cached[:reliever_medications]
    @active_illness       = cached[:active_illness]
  end
end
