# frozen_string_literal: true

class PreventerHistoryController < ApplicationController
  def index
    authorize :preventer_history, :index?
    user = Current.user
    @period = params[:period].to_i.in?([ 7, 30 ]) ? params[:period].to_i : 7

    date_range = (@period - 1).days.ago.to_date..Date.current

    # Only preventers with a doses_per_day schedule — same rule as dashboard.
    # Excludes course medications (COURSE-03): temporary courses are not adherence history targets.
    preventers = user.medications
      .where(medication_type: :preventer)
      .where(course: false)
      .where.not(doses_per_day: nil)
      .chronological

    # Fix #6: batch-load all dose logs for the period in one query (avoids N×period queries)
    all_logs = user.dose_logs
      .where(medication: preventers)
      .where(recorded_at: date_range.begin.beginning_of_day..date_range.end.end_of_day)
      .group_by { |log| [ log.medication_id, log.recorded_at.to_date ] }

    # Fix #5: Monday-aligned grid offset and the actual dates of padding cells (30-day only)
    if @period == 30
      start_date    = date_range.first
      @grid_offset  = (start_date.wday - 1) % 7   # wday: 0=Sun → Monday offset = 6
      @padding_dates = @grid_offset.times.map { |i| start_date - (@grid_offset - i) }
    else
      @grid_offset   = 0
      @padding_dates = []
    end

    # Header eyebrow: distinct days with at least one dose logged this month
    month_start = Date.current.beginning_of_month
    @header_days_taken   = user.dose_logs
                               .where(recorded_at: month_start..)
                               .distinct
                               .count("DATE(recorded_at)")
    @header_days_elapsed = (Date.current - month_start).to_i + 1

    @adherence_history = preventers.map do |medication|
      days_data = date_range.map do |date|
        logs   = all_logs[[ medication.id, date ]]
        result = AdherenceCalculator.call(medication, date, preloaded_logs: logs)
        { date: date, result: result }
      end
      { medication: medication, days_data: days_data }
    end

    respond_to do |format|
      format.html
      format.json do
        render json: {
          period:            @period,
          days_taken:        @header_days_taken,
          days_elapsed:      @header_days_elapsed,
          adherence_history: @adherence_history.map { |entry| adherence_history_json(entry) }
        }
      end
    end
  end

  private

  def adherence_history_json(entry)
    medication = entry[:medication]
    {
      medication_id:   medication.id,
      medication_name: medication.name,
      doses_per_day:   medication.doses_per_day,
      days_data:       entry[:days_data].map { |day| adherence_day_json(day) }
    }
  end

  def adherence_day_json(day)
    result = day[:result]
    {
      date:      day[:date].to_s,
      taken:     result.taken,
      scheduled: result.scheduled,
      status:    result.status
    }
  end
end
