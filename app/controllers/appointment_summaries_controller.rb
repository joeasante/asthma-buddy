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

    respond_to do |format|
      format.html
      format.json { render json: health_report_json }
    end
  end

  private

    def health_report_json
      {
        period_start: @period_start,
        peak_flow: {
          reading_count: @reading_count,
          average: @avg,
          best: @best_in_period,
          worst: @worst_in_period,
          personal_best: @personal_best&.value,
          zones: @zone_counts,
          readings: @individual_readings.map { |r|
            { id: r.id, value: r.value, zone: r.zone, time_of_day: r.time_of_day, recorded_at: r.recorded_at }
          }
        },
        symptoms: {
          count: @symptom_count,
          severity_breakdown: @severity_breakdown,
          logs: @symptom_logs.map { |l|
            { id: l.id, type: l.symptom_type, severity: l.severity, recorded_at: l.recorded_at, triggers: l.triggers, notes: l.notes&.to_plain_text }
          }
        },
        reliever_use: {
          total_doses: @reliever_doses_total,
          avg_per_week: @reliever_doses_per_week,
          within_range: @reliever_doses_per_week <= 2
        },
        medications: @active_medications.map { |m|
          { id: m.id, name: m.name, type: m.medication_type, dose: m.standard_dose_puffs, dose_unit: m.dose_unit }
        },
        courses: @period_courses.map { |c|
          { id: c.id, name: c.name, dose: c.standard_dose_puffs, dose_unit: c.dose_unit, starts_on: c.starts_on, ends_on: c.ends_on }
        },
        health_events: @health_events.map { |e|
          { id: e.id, type: e.event_type, recorded_at: e.recorded_at, ended_at: e.ended_at, notes: e.notes&.to_plain_text }
        }
      }
    end
end
