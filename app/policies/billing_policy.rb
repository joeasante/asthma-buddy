# frozen_string_literal: true

class BillingPolicy < ApplicationPolicy
  def show?
    true # All authenticated users can view billing page
  end

  def checkout?
    user.free? # Only free users can initiate checkout
  end

  def portal?
    user.premium? && !user.admin? # Only paying premium users can access portal
  end
end
