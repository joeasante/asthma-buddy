# frozen_string_literal: true

class PersonalBestRecord < ApplicationRecord
  STALE_THRESHOLD = 12.months

  belongs_to :user

  validates :value, presence: true,
                    numericality: { only_integer: true,
                                    greater_than_or_equal_to: 100,
                                    less_than_or_equal_to: 900,
                                    message: "must be between 100 and 900 L/min" }
  validates :recorded_at, presence: true
  validate :recorded_at_within_acceptable_range, if: -> { recorded_at.present? }

  after_save :recompute_nil_zone_readings, if: -> { saved_change_to_value? || previously_new_record? }

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

  # When a personal best is saved, recompute the zone for any readings that had
  # no zone (typically recorded before a personal best was ever set, or affected
  # by the same-minute timestamp edge case). Uses the newly saved personal best
  # value directly so the fix applies regardless of timestamp ordering.
  def recompute_nil_zone_readings
    nil_zone_readings = user.peak_flow_readings.where(zone: nil).to_a
    return if nil_zone_readings.empty?

    green_ids  = []
    yellow_ids = []
    red_ids    = []

    nil_zone_readings.each do |reading|
      pct = (reading.value.to_f / self.value) * 100
      if pct >= PeakFlowReading::GREEN_ZONE_THRESHOLD
        green_ids  << reading.id
      elsif pct >= PeakFlowReading::YELLOW_ZONE_THRESHOLD
        yellow_ids << reading.id
      else
        red_ids    << reading.id
      end
    end

    PeakFlowReading.where(user_id: user.id, id: green_ids).update_all(zone: PeakFlowReading.zones["green"])   unless green_ids.empty?
    PeakFlowReading.where(user_id: user.id, id: yellow_ids).update_all(zone: PeakFlowReading.zones["yellow"]) unless yellow_ids.empty?
    PeakFlowReading.where(user_id: user.id, id: red_ids).update_all(zone: PeakFlowReading.zones["red"])       unless red_ids.empty?
  end

  def recorded_at_within_acceptable_range
    if recorded_at > 5.minutes.from_now
      errors.add(:recorded_at, "cannot be in the future")
    elsif recorded_at < 1.year.ago
      errors.add(:recorded_at, "cannot be more than 1 year in the past")
    end
  end
end
