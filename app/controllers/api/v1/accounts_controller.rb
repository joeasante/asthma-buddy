# frozen_string_literal: true

module Api
  module V1
    class AccountsController < BaseController
      def show
        authorize :account, :destroy? # reuse existing policy — any authenticated user can view their own account

        user = Current.user
        render json: {
          data: {
            id: user.id,
            email: user.email_address,
            plan: user.plan_name.downcase,
            subscription_status: user.subscription_status,
            on_trial: user.on_trial?,
            trial_ends_at: user.trial_ends_at,
            next_billing_date: user.next_billing_date
          }
        }
      end
    end
  end
end
