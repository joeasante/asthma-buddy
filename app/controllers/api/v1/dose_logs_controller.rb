# frozen_string_literal: true

module Api
  module V1
    class DoseLogsController < BaseController
      def index
        authorize DoseLog

        scope = policy_scope(DoseLog).includes(:medication).order(recorded_at: :desc)
        scope = date_filter(scope, date_column: :recorded_at)
        result = paginate(scope)

        render json: {
          data: result[:records].map { |log|
            {
              id: log.id,
              medication_id: log.medication_id,
              medication_name: log.medication.name,
              puffs: log.puffs,
              recorded_at: log.recorded_at,
              created_at: log.created_at
            }
          },
          meta: result[:meta]
        }
      end
    end
  end
end
