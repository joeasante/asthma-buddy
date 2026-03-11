# frozen_string_literal: true

class Settings::BaseController < ApplicationController
  private

  def set_header_eyebrow_vars
    all_meds = Current.user.medications.chronological.includes(:dose_logs)
    visible  = all_meds.reject { |m| m.course? && !m.course_active? }
    @header_medication_count = visible.size
    @header_low_stock_count  = visible.count(&:low_stock?)
  end

  # NOTE: set_dashboard_vars rebuilds dashboard queries for the Turbo Stream
  # response that updates today-doses-list on the dashboard. This is intentional
  # cross-namespace behavior: the dashboard quick-log UI submits to
  # Settings::DoseLogsController#create, and the dashboard partial is updated
  # in-place if the user is viewing it. If DashboardController#index ever changes
  # how these variables are assembled, this method must be updated in sync.
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
