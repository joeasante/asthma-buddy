# frozen_string_literal: true

class RelieverUsageController < ApplicationController
  def index
    @weeks = params[:weeks].to_i.in?([ 8, 12 ]) ? params[:weeks].to_i : 8

    period_start = @weeks.weeks.ago.to_date
    date_range   = period_start..Date.current

    @relievers = Current.user.medications
      .where(medication_type: :reliever)
      .chronological

    if @relievers.empty?
      @weekly_data = []
      @correlation = nil
      setup_monthly_stats
      return
    end

    all_logs = Current.user.dose_logs
      .where(medication: @relievers)
      .where(recorded_at: date_range.first.beginning_of_day..date_range.last.end_of_day)

    @has_logs = all_logs.any?

    unless @has_logs
      @weekly_data = []
      @correlation = nil
      setup_monthly_stats
      return
    end

    @weekly_data = build_weekly_data(all_logs.to_a, period_start)

    # Peak flow correlation
    pf_readings = Current.user.peak_flow_readings
      .where(recorded_at: date_range.first.beginning_of_day..date_range.last.end_of_day)

    @correlation = build_correlation(@weekly_data, pf_readings.to_a)

    setup_monthly_stats
  end

  private

  def setup_monthly_stats
    month_start = Date.current.beginning_of_month
    @monthly_uses = Current.user.dose_logs
      .where(medication: Current.user.medications.where(medication_type: :reliever))
      .where(recorded_at: month_start.beginning_of_day..)
      .count
    @monthly_pill_class = monthly_pill_class(@monthly_uses)
    @monthly_pill_label = monthly_pill_label(@monthly_uses)
  end

  def build_weekly_data(logs, period_start)
    # Walk week by week, Monday-aligned
    # The first partial week starts at period_start and ends on the following Sunday
    weeks = []
    current = period_start

    while current <= Date.current
      # Find the Monday of this week
      days_since_monday = (current.wday - 1) % 7
      week_monday = current - days_since_monday
      week_sunday = week_monday + 6

      week_start = current  # First iteration may be mid-week
      week_end   = [ week_sunday, Date.current ].min

      uses = logs.count { |l| l.recorded_at.to_date.between?(week_start, week_end) }
      band = gina_band(uses)
      label = week_start.strftime("%-d %b")

      weeks << { week_start: week_start, week_end: week_end, uses: uses, band: band, label: label }

      # Advance to next Monday
      current = week_monday + 7
    end

    weeks
  end

  def gina_band(uses)
    if uses >= 6
      :urgent
    elsif uses >= 3
      :review
    else
      :controlled
    end
  end

  def build_correlation(weekly_data, pf_readings)
    return nil if pf_readings.size < 2

    high_use_weeks = weekly_data.select { |w| w[:uses] >= 3 }
    low_use_weeks  = weekly_data.select { |w| w[:uses] <= 2 }

    return nil if high_use_weeks.empty? || low_use_weeks.empty?

    high_values = readings_in_weeks(pf_readings, high_use_weeks)
    low_values  = readings_in_weeks(pf_readings, low_use_weeks)

    return nil if high_values.empty? || low_values.empty?

    high_avg = high_values.sum.to_f / high_values.size
    low_avg  = low_values.sum.to_f  / low_values.size

    { high_avg: high_avg.round, low_avg: low_avg.round }
  end

  def readings_in_weeks(pf_readings, weeks)
    weeks.flat_map do |w|
      pf_readings
        .select { |r| r.recorded_at.to_date.between?(w[:week_start], w[:week_end]) }
        .map(&:value)
    end
  end

  def monthly_pill_class(uses)
    if uses <= 8
      "eyebrow-pill--green"
    elsif uses <= 15
      "eyebrow-pill--amber"
    else
      "eyebrow-pill--red"
    end
  end

  def monthly_pill_label(uses)
    if uses <= 8
      "Well controlled"
    elsif uses <= 15
      "Review recommended"
    else
      "Speak to your GP"
    end
  end
end
