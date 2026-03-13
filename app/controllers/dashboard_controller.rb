# frozen_string_literal: true

class DashboardController < ApplicationController
  include DashboardVariables

  before_action :check_onboarding

  def index
    user = Current.user

    @personal_best = PersonalBestRecord.current_for(user)

    # Latest single reading — status card
    @last_reading = user.peak_flow_readings.chronological.first

    # Best reading recorded today — used in the page header eyebrow
    @todays_best_reading = user.peak_flow_readings
      .where(recorded_at: Date.current.beginning_of_day..Date.current.end_of_day)
      .order(value: :desc)
      .first

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
      .limit(9)
      .group_by { |r| r.recorded_at.to_date }
      .first(3)
    @recent_symptoms = user.symptom_logs.in_date_range(week_start, nil).chronological.includes(:rich_text_notes).limit(4)

    # Totals for "View all N" section footers — cheap indexed COUNT queries.
    @total_reading_count   = user.peak_flow_readings.count
    @total_symptom_count   = user.symptom_logs.count
    @total_health_event_count = user.health_events.count

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
      .map(&:to_chart_marker)

    # Duration events that started before this week and are still ongoing.
    # These have no valid x-axis position so they can't be chart markers,
    # but they're clinically relevant context shown as an "Active" strip below the chart.
    @ongoing_health_events = user.health_events
      .where(recorded_at: ...week_start.beginning_of_day)
      .where(ended_at: nil)
      .where.not(event_type: HealthEvent::POINT_IN_TIME_TYPES)
      .order(recorded_at: :asc)

    # Low-stock medications — loaded with dose_logs to avoid N+1 in low_stock?
    # Exclude course medications at query level (low_stock? also returns false for course_active?,
    # but excluding at the DB level avoids loading unnecessary course records).
    @low_stock_medications = user.medications
      .where(course: false)
      .includes(:dose_logs)
      .select(&:low_stock?)

    # Recent health events — ongoing duration events (any age) + any event in last 14 days.
    # Ongoing = ended_at IS NULL AND not a point-in-time type (appointments never have ended_at,
    # so we'd include every old appointment without the POINT_IN_TIME_TYPES exclusion).
    fourteen_days_ago = 14.days.ago.beginning_of_day
    @recent_health_events = user.health_events
      .where(
        "recorded_at >= ? OR (ended_at IS NULL AND event_type NOT IN (?))",
        fourteen_days_ago,
        HealthEvent::POINT_IN_TIME_TYPES
      )
      .recent_first
      .limit(3)

    # Today's preventer adherence, reliever medications, and active illness —
    # shared with Settings::BaseController via the DashboardVariables concern.
    set_dashboard_vars

    respond_to do |format|
      format.html
      format.json { render json: dashboard_json }
    end
  end

  private

    def dashboard_json
      {
        peak_flow: {
          latest:        @last_reading&.as_json(only: %i[id value zone time_of_day recorded_at]),
          personal_best: @personal_best&.value,
          week_avg:      @week_avg,
          week_avg_zone: @week_avg_zone,
          week_count:    @week_reading_count
        },
        symptoms: {
          week_count:      @week_symptom_count,
          severity_counts: @week_severity_counts,
          last_severe:     @last_severe&.as_json(only: %i[id severity recorded_at])
        },
        medications: {
          low_stock_count:      @low_stock_medications.size,
          low_stock_medication_ids: @low_stock_medications.map(&:id)
        },
        health_events: {
          total:         @total_health_event_count,
          active_illness: @active_illness&.as_json(only: %i[id event_type recorded_at])
        },
        totals: {
          readings: @total_reading_count,
          symptoms: @total_symptom_count
        }
      }
    end

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
