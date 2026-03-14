# frozen_string_literal: true

class DoseLogPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    true
  end

  def destroy?
    owner?
  end
end
