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

    # Remove any orphaned ActionText rich-text rows left behind when the
    # health_events table was previously rolled back. The polymorphic
    # action_text_rich_texts table has no foreign key on record_id, so those
    # rows are not cascade-deleted when the parent table is dropped.
    reversible do |dir|
      dir.up do
        execute "DELETE FROM action_text_rich_texts WHERE record_type = 'HealthEvent'"
      end
    end
  end
end
