# frozen_string_literal: true
class PeakFlowReading < ApplicationRecord
  belongs_to :user

  enum :zone, { green: 0, yellow: 1, red: 2 }, validate: { allow_nil: true }

  validates :value, presence: true,
                    numericality: { only_integer: true, greater_than: 0 }
  validates :recorded_at, presence: true

  scope :chronological, -> { order(recorded_at: :desc) }

  # Returns the personal best value for this user at the time of this reading.
  # Looks for the most recent PersonalBestRecord with recorded_at <= self.recorded_at.
  # Returns nil if no personal best exists before this reading.
  def personal_best_at_reading_time
    user.personal_best_records
        .where("recorded_at <= ?", recorded_at)
        .order(recorded_at: :desc)
        .pick(:value)
  end

  # Compute zone from value vs personal best at reading time.
  # Returns :green, :yellow, :red, or nil (no personal best).
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

  # Assign zone before save based on current personal best history.
  # Sets zone to nil if no personal best record exists.
  before_save :assign_zone

  private

  def assign_zone
    self.zone = compute_zone
  end
end
