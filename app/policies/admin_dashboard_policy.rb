# frozen_string_literal: true

class AdminDashboardPolicy < ApplicationPolicy
  def index?
    admin?
  end
end
