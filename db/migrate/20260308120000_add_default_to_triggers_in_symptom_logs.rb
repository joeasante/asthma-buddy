# frozen_string_literal: true

class AddDefaultToTriggersInSymptomLogs < ActiveRecord::Migration[8.1]
  def up
    change_column_default :symptom_logs, :triggers, from: nil, to: "[]"
    SymptomLog.where(triggers: nil).update_all(triggers: "[]")
  end

  def down
    change_column_default :symptom_logs, :triggers, from: "[]", to: nil
  end
end
