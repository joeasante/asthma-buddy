# frozen_string_literal: true

class RelieverUsageController < ApplicationController
  GINA_REVIEW_THRESHOLD  = 3
  GINA_URGENT_THRESHOLD  = 6
  BAR_MAX_SCALE          = GINA_URGENT_THRESHOLD.to_f

  MONTHLY_CONTROL_TIERS = [
    { max: 8,              css: "eyebrow-pill--green", label: "Well controlled"    },
    { max: 15,             css: "eyebrow-pill--amber", label: "Review recommended" },
    { max: Float::INFINITY, css: "eyebrow-pill--red",  label: "Speak to your GP"  }
  ].freeze

  rate_limit to: 60, within: 1.minute, with: -> {
    respond_to do |format|
      format.html { render plain: "Too many requests", status: :too_many_requests }
      format.json { render json: { error: "Too many requests" }, status: :too_many_requests }
    end
  }

  def index
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
    else
      setup_monthly_stats
    end

    unless @relievers.empty?
      loaded_logs = Current.user.dose_logs
        .where(medication: @relievers)
        .where(recorded_at: period_start.beginning_of_day..Date.current.end_of_day)
        .to_a

      @has_logs = loaded_logs.any?

      if @has_logs
        @weekly_data = build_weekly_data(loaded_logs, period_start)

        pf_readings  = Current.user.peak_flow_readings
          .where(recorded_at: period_start.beginning_of_day..Date.current.end_of_day)
          .to_a

        @correlation = build_correlation(@weekly_data, pf_readings)
      end
    end

    respond_to do |format|
      format.html
      format.json { render json: reliever_usage_json }
    end
  end

  private

  def setup_monthly_stats
    if @relievers.empty?
      @monthly_uses = 0
    else
      @monthly_uses = Current.user.dose_logs
        .where(medication: @relievers)
        .where(recorded_at: Date.current.beginning_of_month.beginning_of_day..)
        .count
    end
    tier = monthly_control_tier(@monthly_uses)
    @monthly_pill_class = tier[:css]
    @monthly_pill_label = tier[:label]
  end

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
        band:       gina_band(uses),
        label:      week_start.strftime("%-d %b")
      }

      current += 7
    end

    weeks.last(@weeks)
  end

  def gina_band(uses)
    if uses >= GINA_URGENT_THRESHOLD
      :urgent
    elsif uses >= GINA_REVIEW_THRESHOLD
      :review
    else
      :controlled
    end
  end

  def build_correlation(weekly_data, pf_readings)
    return nil if pf_readings.size < 2

    high_use_weeks = weekly_data.select { |w| w[:uses] >= GINA_REVIEW_THRESHOLD }
    low_use_weeks  = weekly_data.select { |w| w[:uses] <  GINA_REVIEW_THRESHOLD }

    return nil if high_use_weeks.empty? || low_use_weeks.empty?

    high_values = high_use_weeks.flat_map { |w|
      pf_readings.select { |r| r.recorded_at.to_date.between?(w[:week_start], w[:week_end]) }.map(&:value)
    }
    low_values = low_use_weeks.flat_map { |w|
      pf_readings.select { |r| r.recorded_at.to_date.between?(w[:week_start], w[:week_end]) }.map(&:value)
    }

    return nil if high_values.empty? || low_values.empty?

    high_avg = high_values.sum.to_f / high_values.size
    low_avg  = low_values.sum.to_f  / low_values.size

    { high_avg: high_avg.round, low_avg: low_avg.round }
  end

  def monthly_control_tier(uses)
    MONTHLY_CONTROL_TIERS.find { |t| uses <= t[:max] }
  end

  def reliever_usage_json
    {
      weeks:        @weeks,
      weekly_data:  @weekly_data.map { |w|
        { week_start: w[:week_start], week_end: w[:week_end],
          uses: w[:uses], band: w[:band].to_s, label: w[:label] }
      },
      monthly_uses:   @monthly_uses,
      monthly_status: @monthly_pill_label,
      correlation:    @correlation,
      gina_bands: {
        controlled: "0-#{GINA_REVIEW_THRESHOLD - 1} uses/week",
        review:     "#{GINA_REVIEW_THRESHOLD}-#{GINA_URGENT_THRESHOLD - 1} uses/week",
        urgent:     "#{GINA_URGENT_THRESHOLD}+ uses/week"
      }
    }
  end
end
