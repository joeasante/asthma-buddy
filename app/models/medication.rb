# frozen_string_literal: true
class Medication < ApplicationRecord
  belongs_to :user

  enum :medication_type, {
    reliever:    0,
    preventer:   1,
    combination: 2,
    other:       3
  }, validate: true

  validates :name,               presence: true, length: { maximum: 100 }
  validates :standard_dose_puffs, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :starting_dose_count, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sick_day_dose_puffs,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validates :doses_per_day,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true

  scope :chronological, -> { order(created_at: :desc) }
end
