# frozen_string_literal: true

module ApiAuthenticatable
  extend ActiveSupport::Concern

  class_methods do
    def authenticate_by_api_key(token)
      return nil if token.blank?

      digest = Digest::SHA256.hexdigest(token)
      find_by(api_key_digest: digest)
    end
  end

  # Generates a new API key, stores the SHA-256 digest, returns the plaintext token (shown once).
  def generate_api_key!
    token = SecureRandom.hex(32)
    digest = Digest::SHA256.hexdigest(token)
    update!(api_key_digest: digest, api_key_created_at: Time.current)
    token
  end

  # Revokes the API key by clearing the digest and timestamp.
  def revoke_api_key!
    update!(api_key_digest: nil, api_key_created_at: nil)
  end

  # Returns true if the user has an active API key.
  def api_key_active?
    api_key_digest.present?
  end
end
