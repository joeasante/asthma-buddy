# frozen_string_literal: true

class ApiKeyPolicy < ApplicationPolicy
  def show?
    true # All users can see the API key page (free users see upgrade prompt)
  end

  def create?
    user.premium? # Only premium users can generate keys
  end

  def destroy?
    user.premium? # Only premium users can revoke keys (they had to be premium to create one)
  end
end
