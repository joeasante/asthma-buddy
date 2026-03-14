# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def toggle_admin?
    return false unless admin?
    return false if record == user

    # Last-admin protection: cannot demote the last admin
    !record.admin? || User.admin.count > 1
  end

  def update_role?
    admin? && record != user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
