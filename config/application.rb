# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AsthmaBuddy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Security headers applied globally to all responses.
    # Referrer-Policy: prevents URL path leakage to external sites (health data in paths).
    # Permissions-Policy: explicitly denies browser API access (camera, mic, geo) to limit
    # XSS blast radius in a HIPAA-adjacent health app.
    config.action_dispatch.default_headers.merge!(
      "Referrer-Policy" => "strict-origin-when-cross-origin",
      "Permissions-Policy" => "camera=(), microphone=(), geolocation=(), payment=()"
    )

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # IMPORTANT: peak_flow_readings has a unique index on DATE(recorded_at) evaluated
    # in UTC (see db/migrate/20260311200000_add_unique_session_index_to_peak_flow_readings.rb).
    # Changing config.time_zone to a non-UTC value will break duplicate session detection
    # for users near midnight in their local timezone. Both the index and the
    # one_session_per_day model validation must be audited together if timezone changes.
    config.time_zone = "London"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
