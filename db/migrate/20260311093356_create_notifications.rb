class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :notifiable_type
      t.integer :notifiable_id
      t.integer :notification_type, null: false
      t.string  :body,            null: false
      t.boolean :read,            null: false, default: false
      t.timestamps
    end

    add_index :notifications, [ :user_id, :read ]
    add_index :notifications, [ :notifiable_type, :notifiable_id ]
  end
end
