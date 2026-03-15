# frozen_string_literal: true

class PricingController < ApplicationController
  skip_pundit
  allow_unauthenticated_access

  def show
  end
end
