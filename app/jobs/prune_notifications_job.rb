# frozen_string_literal: true

class PruneNotificationsJob < ApplicationJob
  queue_as :default

  def perform
    Notification.pruneable.delete_all
  end
end
