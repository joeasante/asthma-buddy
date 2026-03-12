# frozen_string_literal: true

class HealthEvent < ApplicationRecord
  belongs_to :user
  has_rich_text :notes

  enum :event_type, {
    hospital_visit:    "hospital_visit",
    gp_appointment:    "gp_appointment",
    illness:           "illness",
    medication_change: "medication_change",
    other:             "other"
  }, validate: true

  TYPE_LABELS = {
    "hospital_visit"    => "Hospital visit",
    "gp_appointment"    => "GP appointment",
    "illness"           => "Illness",
    "medication_change" => "Medication change",
    "other"             => "Other"
  }.freeze

  # Short labels used on the 7-day chart markers.
  CHART_LABELS = {
    "hospital_visit"    => "Hosp",
    "gp_appointment"    => "GP",
    "illness"           => "Ill",
    "medication_change" => "Rx",
    "other"             => "Evt"
  }.freeze

  # Event types that represent a single moment in time — no end date applies.
  POINT_IN_TIME_TYPES = %w[gp_appointment medication_change].freeze

  EARLIEST_VALID_DATE = Date.new(1900, 1, 1)

  validates :event_type, presence: true
  validates :recorded_at, presence: true
  validate :ended_at_after_recorded_at
  validate :recorded_at_within_bounds
  validate :ended_at_within_bounds

  scope :recent_first, -> { order(recorded_at: :desc) }

  def event_type_label
    TYPE_LABELS[event_type]
  end

  def event_type_css_modifier
    event_type.tr("_", "-")
  end

  def chart_label
    CHART_LABELS[event_type] || "Evt"
  end

  def to_chart_marker
    marker = {
      date:         recorded_at.to_date.to_s,
      type:         event_type,
      label:        chart_label,
      css_modifier: event_type_css_modifier
    }
    marker[:end_date] = ended_at.to_date.to_s if !point_in_time? && ended_at.present?
    marker
  end

  def point_in_time?
    POINT_IN_TIME_TYPES.include?(event_type)
  end

  def ongoing?
    !point_in_time? && ended_at.nil?
  end

  # Human-readable duration between recorded_at and ended_at.
  # Examples: "3d 4h", "9d", "6h"
  def formatted_duration
    return unless ended_at.present? && recorded_at.present?
    total_seconds = (ended_at - recorded_at).to_i
    days  = total_seconds / 86_400
    hours = (total_seconds % 86_400) / 3_600
    if days > 0
      hours > 0 ? "#{days}d #{hours}h" : "#{days}d"
    else
      "#{hours}h"
    end
  end

  private

  def ended_at_after_recorded_at
    return unless ended_at.present? && recorded_at.present?
    errors.add(:ended_at, "must be after the start date") if ended_at <= recorded_at
  end

  def recorded_at_within_bounds
    return unless recorded_at.present?
    if recorded_at > Time.current + 1.minute
      errors.add(:recorded_at, "cannot be in the future")
    elsif recorded_at.to_date < EARLIEST_VALID_DATE
      errors.add(:recorded_at, "is too far in the past")
    end
  end

  def ended_at_within_bounds
    return unless ended_at.present?
    errors.add(:ended_at, "cannot be in the future") if ended_at > Time.current + 1.minute
  end
end
