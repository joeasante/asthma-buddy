# frozen_string_literal: true

class ProfilePolicy < ApplicationPolicy
  def show?
    true
  end

  def update?
    true
  end

  def update_personal_best?
    true
  end

  def remove_avatar?
    true
  end
end
