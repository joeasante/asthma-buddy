# frozen_string_literal: true

class AppointmentSummariesController < ApplicationController
  def show
    user = Current.user
    period_start = 30.days.ago.to_date

    @period_start = period_start
    @personal_best = PersonalBestRecord.current_for(user)

    @readings = user.peak_flow_readings
      .where(recorded_at: period_start.beginning_of_day..)
      .order(:recorded_at)

    @reading_count   = @readings.count
    @avg             = @readings.average(:value)&.round
    @best_in_period  = @readings.maximum(:value)
    @worst_in_period = @readings.minimum(:value)
    @zone_counts     = @readings.group(:zone).count

    @symptom_count       = user.symptom_logs.where(recorded_at: period_start..).count
    @severity_breakdown  = user.symptom_logs.where(recorded_at: period_start..).group(:severity).count

    reliever_ids = user.medications.where(medication_type: :reliever, course: false).pluck(:id)
    @reliever_doses_total = reliever_ids.any? ?
      user.dose_logs.where(medication_id: reliever_ids, recorded_at: period_start..).count : 0
    @reliever_doses_per_week = (@reliever_doses_total / 4.0).round(1)

    @active_medications = user.medications.where(course: false).order(:name)
    @active_courses     = user.medications.active_courses.order(:ends_on)

    @health_events = user.health_events
      .where("recorded_at >= ? OR ended_at IS NULL", period_start)
      .order(:recorded_at)
  end
end
