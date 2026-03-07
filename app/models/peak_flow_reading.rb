# frozen_string_literal: true
class PeakFlowReading < ApplicationRecord
  belongs_to :user

  enum :zone, { green: 0, yellow: 1, red: 2 }, validate: { allow_nil: true }

  # British Thoracic Society peak flow zone thresholds (% of personal best)
  GREEN_ZONE_THRESHOLD  = 80
  YELLOW_ZONE_THRESHOLD = 50

  validates :value, presence: true,
                    numericality: { only_integer: true, greater_than: 0,
                                    less_than_or_equal_to: 900,
                                    message: "must be between 1 and 900 L/min" }
  validates :recorded_at, presence: true
  validate :recorded_at_within_acceptable_range, if: -> { recorded_at.present? }

  # Zone is computed once at save time and persisted as a snapshot.
  # This preserves the historical zone classification shown to the user at the moment of recording.
  # IMPORTANT: If personal_best_records ever become editable or deletable, a background job
  # (Solid Queue) must recompute zone for all affected peak_flow_readings. Without this,
  # historical zone data will silently become stale.
  before_save { self.zone = compute_zone }

  scope :chronological, -> { order(recorded_at: :desc) }

  def personal_best_at_reading_time
    # Not memoized — recorded_at can change on update (future edit action), which
    # would make a memoized result stale for before_save recomputation.
    user.personal_best_records
        .where("recorded_at <= ?", recorded_at)
        .order(recorded_at: :desc)
        .pick(:value)
  end

  def compute_zone
    pct = zone_pct
    return nil if pct.nil?
    if pct >= GREEN_ZONE_THRESHOLD then :green
    elsif pct >= YELLOW_ZONE_THRESHOLD then :yellow
    else :red
    end
  end

  def zone_percentage
    zone_pct&.round
  end

  private

  def zone_pct
    pb = personal_best_at_reading_time
    return nil if pb.nil? || pb.zero?
    (value.to_f / pb) * 100
  end

  def recorded_at_within_acceptable_range
    if recorded_at > 5.minutes.from_now
      errors.add(:recorded_at, "cannot be in the future")
    elsif recorded_at < 1.year.ago
      errors.add(:recorded_at, "cannot be more than 1 year in the past")
    end
  end
end
