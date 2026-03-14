# frozen_string_literal: true

module Api
  module V1
    class InvalidDateParam < StandardError; end

    class BaseController < ActionController::API
      include Pundit::Authorization

      after_action :verify_authorized

      before_action :authenticate_api_key!
      before_action :set_cache_headers

      rescue_from Pundit::NotAuthorizedError do |_exception|
        render_error(status: 403, message: "Forbidden")
      end

      rescue_from ActiveRecord::RecordNotFound do |_exception|
        render_error(status: 404, message: "Not found")
      end

      rescue_from InvalidDateParam do |exception|
        render_error(status: 400, message: exception.message)
      end

      private

      def pundit_user
        Current.user
      end

      def authenticate_api_key!
        token = extract_bearer_token
        if token.blank?
          render_error(status: 401, message: "Missing or invalid Authorization header")
          return
        end

        user = User.authenticate_by_api_key(token)
        if user.nil?
          render_error(status: 401, message: "Invalid API key")
          return
        end

        Current.user = user
      end

      def extract_bearer_token
        header = request.headers["Authorization"]
        return nil unless header.present?

        match = header.match(/\ABearer\s+([a-f0-9]{64})\z/)
        match&.captures&.first
      end

      def paginate(scope)
        page = [(params[:page] || 1).to_i, 1].max
        per_page = [(params[:per_page] || 25).to_i, 1].max
        per_page = [per_page, 100].min

        total = scope.count
        offset = (page - 1) * per_page
        records = scope.offset(offset).limit(per_page)

        { records: records, meta: { page: page, per_page: per_page, total: total } }
      end

      def date_filter(scope, date_column: :recorded_at)
        column = scope.arel_table[date_column]

        if params[:date_from].present?
          from_date = Date.parse(params[:date_from])
          scope = scope.where(column.gteq(from_date.beginning_of_day))
        end

        if params[:date_to].present?
          to_date = Date.parse(params[:date_to])
          scope = scope.where(column.lteq(to_date.end_of_day))
        end

        scope
      rescue Date::Error
        raise InvalidDateParam, "Invalid date format. Use YYYY-MM-DD."
      end

      def set_cache_headers
        response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, private"
        response.headers["Pragma"] = "no-cache"
      end

      def render_error(status:, message:, details: nil)
        render json: { error: { status: status, message: message, details: details }.compact }, status: status
      end
    end
  end
end
