# frozen_string_literal: true

class AddTriggersToSymptomLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :symptom_logs, :triggers, :text
  end
end
