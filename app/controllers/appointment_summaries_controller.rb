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
    @individual_readings = @readings.select(:id, :value, :zone, :time_of_day, :recorded_at)

    @symptom_count       = user.symptom_logs.where(recorded_at: period_start..).count
    @severity_breakdown  = user.symptom_logs.where(recorded_at: period_start..).group(:severity).count
    @symptom_logs = user.symptom_logs
      .where(recorded_at: period_start..)
      .order(recorded_at: :desc)
      .select(:id, :symptom_type, :severity, :recorded_at, :triggers)
      .with_rich_text_notes

    reliever_ids = user.medications.where(medication_type: :reliever, course: false).pluck(:id)
    @reliever_doses_total = reliever_ids.any? ?
      user.dose_logs.where(medication_id: reliever_ids, recorded_at: period_start..).count : 0
    @reliever_doses_per_week = (@reliever_doses_total / 4.0).round(1)
    @dose_logs_with_meds = user.dose_logs
      .where(recorded_at: period_start..)
      .joins(:medication)
      .select("dose_logs.id, dose_logs.puffs, dose_logs.recorded_at, medications.name AS medication_name, medications.medication_type AS med_type")
      .order(recorded_at: :desc)

    @active_medications = user.medications.where(course: false).order(:name)
    @period_courses = user.medications.where(course: true)
      .where("starts_on <= ? AND ends_on >= ?", Date.current, period_start)
      .order(:starts_on)

    @health_events = user.health_events
      .where("recorded_at >= ? OR ended_at IS NULL", period_start)
      .order(recorded_at: :desc)
      .with_rich_text_notes
  end
end
