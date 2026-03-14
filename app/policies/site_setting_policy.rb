# frozen_string_literal: true

class SiteSettingPolicy < ApplicationPolicy
  def update?
    admin?
  end

  def toggle_registration?
    admin?
  end
end
