# frozen_string_literal: true

class AdherenceCalculator
  Result = Struct.new(:taken, :scheduled, :status)

  def self.call(medication, date)
    new(medication, date).call
  end

  def initialize(medication, date)
    @medication = medication
    @date = date
  end

  def call
    if @date < @medication.created_at.to_date
      return Result.new(0, nil, :no_schedule)
    end

    scheduled = @medication.doses_per_day
    taken = @medication.dose_logs
                       .where(recorded_at: @date.beginning_of_day..@date.end_of_day)
                       .count

    status = if scheduled.nil?
               :no_schedule
             elsif taken >= scheduled
               :on_track
             else
               :missed
             end

    Result.new(taken, scheduled, status)
  end
end
