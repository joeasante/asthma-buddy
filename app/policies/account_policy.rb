# frozen_string_literal: true

class AccountPolicy < ApplicationPolicy
  def show?
    true
  end

  def destroy?
    true
  end
end
