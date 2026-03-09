# frozen_string_literal: true
class SymptomLog < ApplicationRecord
  belongs_to :user

  has_rich_text :notes
  def triggers
    raw = read_attribute(:triggers)
    return [] if raw.nil?
    return raw if raw.is_a?(Array)
    parsed = JSON.parse(raw)
    parsed.is_a?(Array) ? parsed : []
  rescue JSON::ParserError
    []
  end

  def triggers=(value)
    write_attribute(:triggers, value.is_a?(Array) ? value.to_json : value.to_s)
  end

  enum :symptom_type, {
    wheezing: 0,
    coughing: 1,
    shortness_of_breath: 2,
    chest_tightness: 3
  }, validate: true

  enum :severity, {
    mild: 0,
    moderate: 1,
    severe: 2
  }, validate: true

  COMMON_TRIGGERS = %w[cold_air exercise pollen dust_mites smoke pet_dander
                       mold stress respiratory_infection strong_smells
                       weather_changes air_pollution too_hot].freeze

  validates :recorded_at, presence: true
  validate :triggers_are_known, if: -> { triggers.present? }

  scope :chronological, -> { order(recorded_at: :desc) }

  # Date range scope: accepts start_date and end_date as Date or Time objects (nil = unbounded)
  scope :in_date_range, ->(start_date, end_date) {
    result = all
    result = result.where(recorded_at: start_date.beginning_of_day..) if start_date.present?
    result = result.where(recorded_at: ..end_date.end_of_day) if end_date.present?
    result
  }

  # Returns hash { mild: N, moderate: N, severe: N } for a given relation
  def self.severity_counts
    group(:severity).count.transform_keys { |k| k.to_sym }
  end

  # Manual pagination: returns [records, total_pages, current_page]
  # Keeps it simple — no gem, just offset/limit arithmetic
  def self.paginate(page:, per_page: 25)
    page = [page.to_i, 1].max
    total = count
    total_pages = [(total.to_f / per_page).ceil, 1].max
    page = [page, total_pages].min
    records = offset((page - 1) * per_page).limit(per_page)
    [records, total_pages, page]
  end

  private

  def triggers_are_known
    unknown = triggers - COMMON_TRIGGERS
    errors.add(:triggers, "contains unknown values: #{unknown.join(', ')}") if unknown.any?
  end
end
