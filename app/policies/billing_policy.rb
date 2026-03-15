# frozen_string_literal: true

class BillingPolicy < ApplicationPolicy
  def show?
    true # All authenticated users can view billing page
  end

  def checkout?
    user.free? || user.paused?
  end

  def portal?
    (user.premium? || user.paused?) && !user.admin?
  end
end
