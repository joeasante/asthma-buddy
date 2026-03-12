# frozen_string_literal: true

class ErrorsController < ApplicationController
  allow_unauthenticated_access

  def not_found
    render status: :not_found
  end

  def internal_server_error
    render status: :internal_server_error
  end
end
