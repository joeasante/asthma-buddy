# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data, "https://fonts.gstatic.com"
    policy.img_src     :self, :data, "blob:"
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self, "https://fonts.googleapis.com"
    policy.connect_src :self
    policy.base_uri    :self
    policy.form_action :self
    policy.frame_ancestors :none
    policy.report_uri "/csp-violations"
  end

  # Fresh 128-bit random nonce per response — never reuse across requests.
  # (Using session.id would allow nonce reuse for the entire session lifetime.)
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Report-only in non-production so violations are logged without blocking.
  # Once zero violations confirmed in production, set to false to enforce.
  config.content_security_policy_report_only = !Rails.env.production?
end
