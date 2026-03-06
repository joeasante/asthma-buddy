# frozen_string_literal: true

class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]

  def index
  end
end
