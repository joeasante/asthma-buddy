# frozen_string_literal: true
class SymptomLog < ApplicationRecord
  belongs_to :user

  has_rich_text :notes

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

  validates :recorded_at, presence: true

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
end
