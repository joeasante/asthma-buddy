# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user

  # In the web flow, user is set from session via the Authentication concern.
  # In the API flow, user is set directly by BaseController#authenticate_api_key!.
  # If neither is set explicitly, fall back to session delegation for backwards compat.
  def user
    super || session&.user
  end
end
