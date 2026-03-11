# frozen_string_literal: true

class Medication < ApplicationRecord
  belongs_to :user
  has_many :dose_logs, dependent: :destroy

  enum :medication_type, {
    reliever:    0,
    preventer:   1,
    combination: 2,
    other:       3,
    tablet:      4
  }, validate: true

  validates :name,               presence: true, length: { maximum: 100 }
  validates :standard_dose_puffs, presence: true,
            numericality: { only_integer: true, greater_than: 0 },
            unless: :course?
  validates :starting_dose_count, presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            unless: :course?
  validates :sick_day_dose_puffs,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true
  validates :doses_per_day,
            numericality: { only_integer: true, greater_than: 0 },
            allow_nil: true

  with_options if: :course? do
    validates :starts_on, presence: true
    validates :ends_on,   presence: true
    validate  :ends_on_must_be_after_starts_on
  end

  before_validation :clear_course_dates_unless_course

  LOW_STOCK_DAYS = 14

  scope :chronological,    -> { order(created_at: :desc) }
  scope :active_courses,   -> { where(course: true).where("ends_on >= ?", Date.current) }
  scope :archived_courses, -> { where(course: true).where("ends_on < ?", Date.current) }
  scope :non_courses,      -> { where(course: false) }

  # Returns true when this is a course medication that hasn't ended yet.
  def course_active?
    course? && ends_on >= Date.current
  end

  # Returns how many doses remain in the current inhaler.
  # Formula: starting count minus every puff ever logged for this medication.
  # NOTE: Phase 13 will introduce a refill action that resets starting_dose_count
  # and records refilled_at. This method will then correctly reflect the
  # post-refill count because starting_dose_count itself is updated on refill.
  def remaining_doses
    return nil if starting_dose_count.nil?
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
  # LOW_STOCK_DAYS remain. Returns false for active courses (they are excluded
  # from stock alerts — COURSE-03) and when doses_per_day is nil (relievers
  # with no schedule must never trigger the low-stock warning).
  def low_stock?
    return false if course_active?
    days = days_of_supply_remaining
    days.present? && days < LOW_STOCK_DAYS
  end

  private

    def clear_course_dates_unless_course
      unless course?
        self.starts_on = nil
        self.ends_on   = nil
      end
    end

    def ends_on_must_be_after_starts_on
      return unless starts_on.present? && ends_on.present?
      if ends_on <= starts_on
        errors.add(:ends_on, "must be after the start date")
      end
    end
end
