# frozen_string_literal: true

class PagesController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :check_session_freshness

  def privacy
  end

  def terms
  end

  def cookie_policy
  end
end
