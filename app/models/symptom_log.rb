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
end
