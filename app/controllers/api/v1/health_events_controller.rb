# frozen_string_literal: true

module Api
  module V1
    class HealthEventsController < BaseController
      def index
        authorize HealthEvent

        scope = policy_scope(HealthEvent).order(recorded_at: :desc)
        scope = date_filter(scope, date_column: :recorded_at)
        result = paginate(scope)

        render json: {
          data: result[:records].map { |event|
            {
              id: event.id,
              event_type: event.event_type,
              recorded_at: event.recorded_at,
              created_at: event.created_at
            }
          },
          meta: result[:meta]
        }
      end
    end
  end
end
