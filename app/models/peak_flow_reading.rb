# frozen_string_literal: true
class PeakFlowReading < ApplicationRecord
  belongs_to :user

  enum :zone, { green: 0, yellow: 1, red: 2 }, validate: { allow_nil: true }

  validates :value, presence: true,
                    numericality: { only_integer: true, greater_than: 0,
                                    less_than_or_equal_to: 900,
                                    message: "must be between 1 and 900 L/min" }
  validates :recorded_at, presence: true

  before_save { self.zone = compute_zone }

  scope :chronological, -> { order(recorded_at: :desc) }

  def personal_best_at_reading_time
    @personal_best_at_reading_time ||= user.personal_best_records
        .where("recorded_at <= ?", recorded_at)
        .order(recorded_at: :desc)
        .pick(:value)
  end

  def compute_zone
    pb = personal_best_at_reading_time
    return nil if pb.nil? || pb.zero?

    percentage = (value.to_f / pb) * 100
    if percentage >= 80
      :green
    elsif percentage >= 50
      :yellow
    else
      :red
    end
  end

  def zone_percentage
    pb = personal_best_at_reading_time
    return nil if pb.nil? || pb.zero?
    ((value.to_f / pb) * 100).round
  end
end
