# frozen_string_literal: true
class PersonalBestRecord < ApplicationRecord
  belongs_to :user

  validates :value, presence: true,
                    numericality: { only_integer: true,
                                    greater_than_or_equal_to: 100,
                                    less_than_or_equal_to: 900,
                                    message: "must be between 100 and 900 L/min" }
  validates :recorded_at, presence: true

  scope :chronological, -> { order(recorded_at: :desc) }

  # Returns the most recent PersonalBestRecord for a user, or nil.
  def self.current_for(user)
    user.personal_best_records.chronological.first
  end
end
