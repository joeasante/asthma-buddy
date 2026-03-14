# frozen_string_literal: true

class MedicationPolicy < OwnerCrudPolicy
  def refill?
    owner?
  end
end
