# frozen_string_literal: true

class PagesController < ApplicationController
  skip_pundit
  allow_unauthenticated_access

  def privacy
  end

  def terms
  end

  def cookie_policy
  end
end
