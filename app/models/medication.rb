# frozen_string_literal: true

class Medication < ApplicationRecord
  include DashboardCacheInvalidatable

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

  after_commit -> { invalidate_dashboard_cache }, on: :create
  after_commit -> { invalidate_dashboard_cache }, on: :update,
    if: -> { saved_change_to_name? || saved_change_to_medication_type? || saved_change_to_standard_dose_puffs? || saved_change_to_sick_day_dose_puffs? || saved_change_to_doses_per_day? || saved_change_to_course? }
  after_commit -> { invalidate_dashboard_cache }, on: :destroy

  LOW_STOCK_DAYS = 14

  scope :chronological,    -> { order(created_at: :desc) }
  scope :active_courses,   -> { where(course: true).where("ends_on >= ?", Date.current) }
  scope :archived_courses, -> { where(course: true).where("ends_on < ?", Date.current) }
  scope :non_courses,      -> { where(course: false) }

  # Returns true when this is a course medication that hasn't ended yet.
  def course_active?
    course? && (ends_on.nil? || ends_on >= Date.current)
  end

  # Returns how many doses remain in the current inhaler.
  # Only counts puffs taken since the last refill (or since creation if never refilled),
  # so the count resets to starting_dose_count when a refill is recorded.
  # Uses dose_logs.loaded? to avoid an extra query when the association is eager-loaded.
  def remaining_doses
    return nil if starting_dose_count.nil?
    since = refilled_at || created_at
    taken = if dose_logs.loaded?
      dose_logs.select { |dl| dl.recorded_at >= since }.sum(&:puffs)
    else
      dose_logs.where("recorded_at >= ?", since).sum(:puffs)
    end
    starting_dose_count - taken
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
