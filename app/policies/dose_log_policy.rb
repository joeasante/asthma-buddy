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

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:medication).where(medications: { user_id: user.id })
    end
  end
end
