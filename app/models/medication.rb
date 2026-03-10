# frozen_string_literal: true

class Medication < ApplicationRecord
  belongs_to :user
  has_many :dose_logs, dependent: :destroy

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

  LOW_STOCK_DAYS = 14

  scope :chronological, -> { order(created_at: :desc) }

  # Returns how many doses remain in the current inhaler.
  # Formula: starting count minus every puff ever logged for this medication.
  # NOTE: Phase 13 will introduce a refill action that resets starting_dose_count
  # and records refilled_at. This method will then correctly reflect the
  # post-refill count because starting_dose_count itself is updated on refill.
  def remaining_doses
    starting_dose_count - dose_logs.sum(:puffs)
  end

  # Returns how many days of supply remain at the current daily dose rate.
  # Returns nil when doses_per_day is blank — callers must guard against nil
  # before displaying or triggering low-stock logic (Phase 13).
  # Rounded to one decimal place for display (e.g. 6.5 days remaining).
  def days_of_supply_remaining
    return nil if doses_per_day.blank? || doses_per_day == 0
    (remaining_doses.to_f / doses_per_day).round(1)
  end

  # Returns true when a days-of-supply estimate is available AND fewer than
  # LOW_STOCK_DAYS remain. Returns false when doses_per_day is nil (relievers
  # with no schedule must never trigger the low-stock warning).
  def low_stock?
    days = days_of_supply_remaining
    days.present? && days < LOW_STOCK_DAYS
  end
end
