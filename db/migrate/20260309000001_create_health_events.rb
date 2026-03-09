# frozen_string_literal: true

class CreateHealthEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :health_events do |t|
      t.references :user, null: false, foreign_key: true
      t.string     :event_type, null: false
      t.datetime   :recorded_at, null: false
      t.datetime   :ended_at

      t.timestamps
    end

    add_index :health_events, [ :user_id, :recorded_at ]
    add_index :health_events, [ :user_id, :ended_at ]
  end
end
