# frozen_string_literal: true
class PersonalBestRecord < ApplicationRecord
  belongs_to :user

  validates :value, presence: true,
                    numericality: { only_integer: true,
                                    greater_than_or_equal_to: 100,
                                    less_than_or_equal_to: 900,
                                    message: "must be between 100 and 900 L/min" }
  validates :recorded_at, presence: true
  validate :recorded_at_within_acceptable_range, if: -> { recorded_at.present? }

  scope :chronological, -> { order(recorded_at: :desc) }

  # Returns the most recent PersonalBestRecord for a user, or nil.
  def self.current_for(user)
    user.personal_best_records.chronological.first
  end

  # Uses EXISTS query — faster than current_for(...).present? for presence checks.
  def self.exists_for?(user)
    user.personal_best_records.exists?
  end

  private

  def recorded_at_within_acceptable_range
    if recorded_at > 5.minutes.from_now
      errors.add(:recorded_at, "cannot be in the future")
    elsif recorded_at < 1.year.ago
      errors.add(:recorded_at, "cannot be more than 1 year in the past")
    end
  end
end
