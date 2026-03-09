# frozen_string_literal: true

class PruneExpiredSessionsJob < ApplicationJob
  queue_as :default

  def perform
    Session.where("created_at < ?", 2.weeks.ago).delete_all
  end
end
