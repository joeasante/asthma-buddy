# frozen_string_literal: true

class AccountPolicy < ApplicationPolicy
  def destroy?
    true
  end
end
