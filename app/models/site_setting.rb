# frozen_string_literal: true

class SiteSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.registration_open?
    Rails.cache.fetch("site_setting:registration_open", expires_in: 5.minutes) do
      find_by(key: "registration_open")&.value == "true"
    end
  end

  def self.toggle_registration!
    setting = find_or_create_by!(key: "registration_open") do |s|
      s.value = "true"
    end
    setting.update!(value: setting.value == "true" ? "false" : "true")
    Rails.cache.delete("site_setting:registration_open")
  end
end
