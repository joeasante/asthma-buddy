# frozen_string_literal: true

module Api
  module V1
    class SymptomLogsController < BaseController
      def index
        authorize SymptomLog

        scope = policy_scope(SymptomLog).order(recorded_at: :desc)
        scope = date_filter(scope, date_column: :recorded_at)
        return unless scope

        result = paginate(scope)

        render json: {
          data: result[:records].map { |log|
            {
              id: log.id,
              symptom_type: log.symptom_type,
              severity: log.severity,
              triggers: log.triggers,
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
