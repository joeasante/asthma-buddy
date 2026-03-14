# frozen_string_literal: true

class SiteSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :value, inclusion: { in: %w[true false] }, if: -> { key == "registration_open" }

  def self.registration_open?
    Rails.cache.fetch("site_setting:registration_open", expires_in: 5.minutes) do
      find_by(key: "registration_open")&.value == "true"
    end
  end

  def self.toggle_registration!
    setting = find_or_create_by!(key: "registration_open") { |s| s.value = "true" }
    setting.with_lock do
      setting.update!(value: setting.value == "true" ? "false" : "true")
    end
    Rails.cache.delete("site_setting:registration_open")
    registration_open?
  end
end
