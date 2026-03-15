# frozen_string_literal: true

class PricingController < ApplicationController
  allow_unauthenticated_access
  skip_pundit

  def show
  end
end
