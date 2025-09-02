class CreateSyncSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :sync_sessions do |t|
      t.references :todo_list, null: false, foreign_key: true
      t.string :status
      t.string :strategy
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :local_changes_count
      t.integer :remote_changes_count
      t.integer :conflicts_count
      t.text :sync_results
      t.text :error_message

      t.timestamps
    end
  end
end
