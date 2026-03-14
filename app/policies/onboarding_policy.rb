# frozen_string_literal: true

class OnboardingPolicy < ApplicationPolicy
  def show?
    true
  end

  def update?
    true
  end

  def submit?
    true
  end

  def skip?
    true
  end
end
