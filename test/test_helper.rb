# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

BCrypt::Engine.cost = BCrypt::Engine::MIN_COST

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    def make_premium(user, status: "active", **overrides)
      user.set_payment_processor :stripe
      user.payment_processor.subscriptions.create!({
        name: "default",
        processor_id: "sub_test_#{user.id}",
        processor_plan: "price_test",
        status: status,
        type: "Pay::Stripe::Subscription"
      }.merge(overrides))
      user.payment_processor.reload
    end
  end
end
