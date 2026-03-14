# frozen_string_literal: true

module Api
  module V1
    class PeakFlowReadingsController < BaseController
      def index
        authorize PeakFlowReading

        scope = policy_scope(PeakFlowReading).order(recorded_at: :desc)
        scope = date_filter(scope, date_column: :recorded_at)
        return unless scope

        result = paginate(scope)

        render json: {
          data: result[:records].map { |reading|
            {
              id: reading.id,
              value: reading.value,
              zone: reading.zone,
              time_of_day: reading.time_of_day,
              recorded_at: reading.recorded_at,
              created_at: reading.created_at
            }
          },
          meta: result[:meta]
        }
      end
    end
  end
end
