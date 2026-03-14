# frozen_string_literal: true

class MedicationPolicy < ApplicationPolicy
  include OwnerCrudPolicy

  def refill?
    owner?
  end
end
