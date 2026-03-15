# frozen_string_literal: true

class AppointmentSummaryPolicy < ApplicationPolicy
  def show?
    true
  end

  def export?
    user.premium?
  end
end
