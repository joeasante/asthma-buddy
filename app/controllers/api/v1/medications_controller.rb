# frozen_string_literal: true

module Api
  module V1
    class MedicationsController < BaseController
      def index
        authorize Medication

        scope = policy_scope(Medication).includes(:dose_logs).order(created_at: :desc)
        result = paginate(scope)

        render json: {
          data: result[:records].map { |med|
            {
              id: med.id,
              name: med.name,
              medication_type: med.medication_type,
              dose_unit: med.dose_unit,
              standard_dose_puffs: med.standard_dose_puffs,
              doses_per_day: med.doses_per_day,
              starting_dose_count: med.starting_dose_count,
              remaining_doses: med.remaining_doses,
              created_at: med.created_at
            }
          },
          meta: result[:meta]
        }
      end
    end
  end
end
