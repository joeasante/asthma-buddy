# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    user = Current.user

    @personal_best = PersonalBestRecord.current_for(user)

    # Latest single reading — status card
    @last_reading = user.peak_flow_readings.chronological.first

    # 7-day window stats
    week_start       = 7.days.ago
    recent_readings  = user.peak_flow_readings.in_date_range(week_start, nil)
    recent_symptoms  = user.symptom_logs.in_date_range(week_start, nil)

    @week_reading_count   = recent_readings.count
    @week_avg             = recent_readings.average(:value)&.round
    @week_symptom_count   = recent_symptoms.count
    @week_severity_counts = { mild: 0, moderate: 0, severe: 0 }.merge(recent_symptoms.severity_counts)

    # Last severe episode (any time, not just this week)
    @last_severe = user.symptom_logs.where(severity: :severe).chronological.first

    # Recent entries — 4 each, feeds the "recent" cards
    @recent_readings = user.peak_flow_readings.chronological.limit(4)
    @recent_symptoms = user.symptom_logs.chronological.includes(:rich_text_notes).limit(4)

    # 7-day chart data — one bar per day showing the best (highest) reading.
    # Multiple readings on the same day would otherwise produce overlapping bars in Chart.js.
    @chart_data = recent_readings
      .reorder(recorded_at: :asc)
      .pluck(:recorded_at, :value, :zone)
      .map { |ts, v, z| { date: ts.to_date.to_s, value: v, zone: z } }
      .group_by { |d| d[:date] }
      .map { |_date, readings| readings.max_by { |r| r[:value] } }
      .sort_by { |d| d[:date] }

    # Low-stock medications — loaded with dose_logs to avoid N+1 in low_stock?
    @low_stock_medications = user.medications.includes(:dose_logs).select(&:low_stock?)
  end
end
