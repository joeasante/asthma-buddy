# frozen_string_literal: true

class RelieverUsageController < ApplicationController
  MONTHLY_CONTROL_TIERS = [
    { max: 8,              css: "eyebrow-pill--green", label: "Well controlled"    },
    { max: 15,             css: "eyebrow-pill--amber", label: "Review recommended" },
    { max: Float::INFINITY, css: "eyebrow-pill--red",  label: "Speak to your GP"  }
  ].freeze

  rate_limit to: 30, within: 1.minute,
             by: -> { Current.session&.id || request.remote_ip },
             with: -> {
               respond_to do |format|
                 format.html { redirect_to reliever_usage_path, alert: "Too many requests. Please slow down.", status: :see_other }
                 format.json { render json: { error: "Too many requests" }, status: :too_many_requests }
               end
             }

  def index
    authorize :reliever_usage, :index?
    @weeks       = params[:weeks].to_i.in?([ 8, 12 ]) ? params[:weeks].to_i : 8
    period_start = @weeks.weeks.ago.to_date

    @relievers   = Current.user.medications.where(medication_type: :reliever).chronological
    @weekly_data = []
    @correlation = nil
    @has_logs    = false

    # Monthly eyebrow stats are outside the Turbo Frame — skip the DB query on frame requests
    # since the rendered HTML is discarded by Turbo anyway.
    if turbo_frame_request?
      tier = MONTHLY_CONTROL_TIERS.first
      @monthly_uses       = 0
      @monthly_pill_class = tier[:css]
      @monthly_pill_label = tier[:label]
    end

    unless @relievers.empty?
      reliever_ids = @relievers.map(&:id)
      loaded_logs = DoseLog
        .where(user_id: Current.user.id, medication_id: reliever_ids)
        .where(recorded_at: period_start.beginning_of_day..Date.current.end_of_day)
        .to_a

      unless turbo_frame_request?
        month_start = Date.current.beginning_of_month.beginning_of_day
        @monthly_uses = loaded_logs.count { |l| l.recorded_at >= month_start }
        tier = monthly_control_tier(@monthly_uses)
        @monthly_pill_class = tier[:css]
        @monthly_pill_label = tier[:label]
      end

      @has_logs = loaded_logs.any?

      if @has_logs
        @weekly_data = build_weekly_data(loaded_logs, period_start)

        pf_readings  = Current.user.peak_flow_readings
          .where(recorded_at: period_start.beginning_of_day..Date.current.end_of_day)
          .to_a

        @correlation = build_correlation(@weekly_data, pf_readings)
      end
    else
      unless turbo_frame_request?
        @monthly_uses = 0
        tier = monthly_control_tier(@monthly_uses)
        @monthly_pill_class = tier[:css]
        @monthly_pill_label = tier[:label]
      end
    end

    respond_to do |format|
      format.html
      format.json { render json: reliever_usage_json }
    end
  end

  private

  def build_weekly_data(logs, period_start)
    # Group logs by date once — O(n) — then look up per week rather than scanning the array
    by_date = logs.group_by { |l| l.recorded_at.to_date }

    # Always start on the Monday of the week containing period_start so all bars
    # represent equal 7-day windows and GINA thresholds apply consistently.
    days_since_monday = (period_start.wday - 1) % 7
    current = period_start - days_since_monday

    weeks = []
    while current <= Date.current
      week_start = current
      week_end   = [ current + 6, Date.current ].min
      uses       = (week_start..week_end).sum { |d| by_date.fetch(d, []).size }

      weeks << {
        week_start: week_start,
        week_end:   week_end,
        uses:       uses,
        band:       DoseLog.gina_band(uses),
        label:      week_start.strftime("%-d %b"),
        fill_pct:   [ (uses / DoseLog::GINA_URGENT_THRESHOLD.to_f * 100).round, 100 ].min
      }

      current += 7
    end

    weeks.last(@weeks)
  end

  def build_correlation(weekly_data, pf_readings)
    return nil if pf_readings.size < 2

    pf_by_date = pf_readings.group_by { |r| r.recorded_at.to_date }

    high_use_weeks = weekly_data.select { |w| w[:uses] >= DoseLog::GINA_REVIEW_THRESHOLD }
    low_use_weeks  = weekly_data.select { |w| w[:uses] <  DoseLog::GINA_REVIEW_THRESHOLD }

    return nil if high_use_weeks.empty? || low_use_weeks.empty?

    values_for = ->(weeks) {
      weeks.flat_map { |w|
        (w[:week_start]..w[:week_end]).flat_map { |d| pf_by_date.fetch(d, []).map(&:value) }
      }
    }

    high_values = values_for.(high_use_weeks)
    low_values  = values_for.(low_use_weeks)

    return nil if high_values.empty? || low_values.empty?

    { high_use_week_avg_peak_flow: (high_values.sum.to_f / high_values.size).round,
      low_use_week_avg_peak_flow:  (low_values.sum.to_f  / low_values.size).round,
      threshold_uses:              DoseLog::GINA_REVIEW_THRESHOLD }
  end

  def monthly_control_tier(uses)
    MONTHLY_CONTROL_TIERS.find { |t| uses <= t[:max] }
  end

  def reliever_usage_json
    {
      weeks:        @weeks,
      weekly_data:  @weekly_data.map { |w|
        { week_start: w[:week_start], week_end: w[:week_end],
          uses: w[:uses], band: w[:band].to_s, label: w[:label], fill_pct: w[:fill_pct] }
      },
      monthly_uses:   @monthly_uses,
      monthly_status: @monthly_pill_label,
      monthly_window: {
        start: Date.current.beginning_of_month.iso8601,
        end:   Date.current.iso8601
      },
      correlation:    @correlation,
      gina_bands: {
        controlled: "0-#{DoseLog::GINA_REVIEW_THRESHOLD - 1} uses/week",
        review:     "#{DoseLog::GINA_REVIEW_THRESHOLD}-#{DoseLog::GINA_URGENT_THRESHOLD - 1} uses/week",
        urgent:     "#{DoseLog::GINA_URGENT_THRESHOLD}+ uses/week"
      }
    }
  end
end
