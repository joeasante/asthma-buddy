# frozen_string_literal: true

class PagesController < ApplicationController
  skip_pundit
  allow_unauthenticated_access

  helper_method :safe_back_url

  def privacy
  end

  def terms
  end

  def cookie_policy
  end

  private

  def safe_back_url
    url_from(request.referer) || root_path
  end
end
