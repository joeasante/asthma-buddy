# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :check_onboarding

  def index
    user = Current.user

    @personal_best = PersonalBestRecord.current_for(user)

    # Latest single reading — status card
    @last_reading = user.peak_flow_readings.chronological.first

    # Current week stats (week starts Monday)
    week_start       = Date.current.beginning_of_week(:monday)
    recent_readings  = user.peak_flow_readings.in_date_range(week_start, nil)
    recent_symptoms  = user.symptom_logs.in_date_range(week_start, nil)

    @week_reading_count   = recent_readings.count
    @week_avg             = recent_readings.average(:value)&.round
    @week_symptom_count   = recent_symptoms.count
    @week_severity_counts = { mild: 0, moderate: 0, severe: 0 }.merge(recent_symptoms.severity_counts)

    # Zone classification for the weekly average — shown on the stat card
    if @week_avg && @personal_best
      pct = (@week_avg.to_f / @personal_best.value) * 100
      @week_avg_zone = if pct >= PeakFlowReading::GREEN_ZONE_THRESHOLD then "green"
                       elsif pct >= PeakFlowReading::YELLOW_ZONE_THRESHOLD then "yellow"
                       else "red"
                       end
    end

    # Last severe episode (any time, not just this week)
    @last_severe = user.symptom_logs.where(severity: :severe).chronological.first

    # Recent entries — feeds the "recent" cards.
    # Peak flow grouped by date (up to 4 days) so AM/PM render side-by-side.
    @recent_readings = user.peak_flow_readings
      .chronological
      .limit(10)
      .group_by { |r| r.recorded_at.to_date }
      .first(4)
    @recent_symptoms = user.symptom_logs.chronological.includes(:rich_text_notes).limit(4)

    # 7-day chart data — one entry per day with separate morning/evening values.
    @chart_data = recent_readings
      .reorder(recorded_at: :asc)
      .pluck(:recorded_at, :value, :zone, :time_of_day)
      .map { |ts, v, z, tod| { date: ts.to_date.to_s, value: v, zone: z, time_of_day: tod || (ts.hour < 13 ? "morning" : "evening") } }
      .group_by { |d| d[:date] }
      .map do |date, readings|
        am = readings.select { |r| r[:time_of_day] == "morning" }.max_by { |r| r[:value] }
        pm = readings.select { |r| r[:time_of_day] == "evening" }.max_by { |r| r[:value] }
        { date: date, morning: am&.dig(:value), morning_zone: am&.dig(:zone), evening: pm&.dig(:value), evening_zone: pm&.dig(:zone) }
      end
      .sort_by { |d| d[:date] }

    # Health event markers for the 7-day chart — one entry per event in window.
    # Chart window matches recent_readings: week_start..Date.current (Mon–today).
    @health_event_markers = user.health_events
      .where(recorded_at: week_start.beginning_of_day..Date.current.end_of_day)
      .order(recorded_at: :asc)
      .map do |e|
        {
          date:         e.recorded_at.to_date.to_s,   # "YYYY-MM-DD"
          type:         e.event_type,
          label:        e.chart_label,
          css_modifier: e.event_type_css_modifier
        }
      end

    # Duration events that started before this week and are still ongoing.
    # These have no valid x-axis position so they can't be chart markers,
    # but they're clinically relevant context shown as an "Active" strip below the chart.
    @ongoing_health_events = user.health_events
      .where(recorded_at: ...week_start.beginning_of_day)
      .where(ended_at: nil)
      .where.not(event_type: HealthEvent::POINT_IN_TIME_TYPES)
      .order(recorded_at: :asc)

    # Low-stock medications — loaded with dose_logs to avoid N+1 in low_stock?
    @low_stock_medications = user.medications.includes(:dose_logs).select(&:low_stock?)

    # Recent health events — 3 most recent, shown in the dashboard card
    @recent_health_events = user.health_events.recent_first.limit(3)

    # Today's preventer adherence — only preventers with a doses_per_day schedule
    today = Date.current
    @preventer_adherence = user.medications
      .where(medication_type: :preventer)
      .includes(:dose_logs)
      .select { |m| m.doses_per_day.present? }
      .map { |m| { medication: m, result: AdherenceCalculator.call(m, today) } }
  end

  private

    # Soft gate — only the dashboard is guarded. Users can navigate directly to
    # data-entry screens (peak flow, symptoms, etc.) without completing onboarding;
    # those controllers handle a missing personal best gracefully. If a hard gate
    # is ever needed, move this to ApplicationController with skip_before_action
    # on OnboardingController, SessionsController, and RegistrationsController.
    def check_onboarding
      return if Current.user.onboarding_complete?
      respond_to do |format|
        format.html { redirect_to onboarding_step_path(1) }
        format.json { render json: { error: "onboarding_required", next_step: 1 }, status: :forbidden }
      end
    end
end
