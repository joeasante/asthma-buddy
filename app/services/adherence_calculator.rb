# frozen_string_literal: true

class AdherenceCalculator
  Result = Struct.new(:taken, :scheduled, :status)

  # Pass preloaded_logs (array) to skip the per-day SQL query when batch-loading.
  def self.call(medication, date, preloaded_logs: nil)
    new(medication, date, preloaded_logs: preloaded_logs).call
  end

  def initialize(medication, date, preloaded_logs: nil)
    @medication     = medication
    @date           = date
    @preloaded_logs = preloaded_logs
  end

  def call
    return Result.new(0, nil, :no_schedule) if @date < @medication.created_at.to_date

    scheduled = @medication.doses_per_day
    taken     = if @preloaded_logs
                  @preloaded_logs.length
    else
                  @medication.dose_logs
                             .where(recorded_at: @date.beginning_of_day..@date.end_of_day)
                             .count
    end

    status = if scheduled.nil?
               :no_schedule
    elsif taken >= scheduled
               :on_track
    elsif @date == Date.current
               # The day is not over — never penalise for a partially completed day.
               # :partial  → at least one dose logged, still waiting on the rest
               # :pending  → nothing logged yet today
               taken > 0 ? :partial : :pending
    else
               :missed
    end

    Result.new(taken, scheduled, status)
  end
end
