# frozen_string_literal: true

class NotificationPolicy < ApplicationPolicy
  def index?
    true
  end

  def mark_read?
    owner?
  end

  def mark_all_read?
    true
  end
end
