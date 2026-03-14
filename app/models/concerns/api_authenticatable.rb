# frozen_string_literal: true

module ApiAuthenticatable
  extend ActiveSupport::Concern

  BEARER_PATTERN = /\ABearer\s+([a-f0-9]{64})\z/
  API_KEY_TTL = 180.days

  class_methods do
    def authenticate_by_api_key(token)
      return nil if token.blank?

      digest = Digest::SHA256.hexdigest(token)
      user = find_by(api_key_digest: digest)
      return nil if user&.api_key_expired?

      user
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

  # Returns true if the API key has exceeded its TTL.
  def api_key_expired?
    return false unless api_key_created_at.present?

    api_key_created_at < API_KEY_TTL.ago
  end

  # Returns the expiry date for the current API key.
  def api_key_expires_at
    return nil unless api_key_created_at.present?

    api_key_created_at + API_KEY_TTL
  end
end
