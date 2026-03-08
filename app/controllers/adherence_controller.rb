# frozen_string_literal: true

class AdherenceController < ApplicationController
  def index
    user = Current.user
    @days = params[:days].to_i.in?([7, 30]) ? params[:days].to_i : 7

    date_range = (@days - 1).days.ago.to_date..Date.current

    # Only preventers with a doses_per_day schedule — same rule as dashboard
    preventers = user.medications
      .where(medication_type: :preventer)
      .where.not(doses_per_day: nil)
      .chronological

    @adherence_history = preventers.map do |medication|
      days_data = date_range.map do |date|
        result = AdherenceCalculator.call(medication, date)
        { date: date, result: result }
      end
      { medication: medication, days_data: days_data }
    end
  end
end
