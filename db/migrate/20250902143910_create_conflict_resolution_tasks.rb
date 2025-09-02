class CreateConflictResolutionTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :conflict_resolution_tasks do |t|
      t.references :sync_session, null: false, foreign_key: true
      t.string :conflict_type
      t.string :status
      t.text :local_data
      t.text :remote_data
      t.text :resolution_data
      t.text :conflict_analysis
      t.datetime :resolved_at
      t.string :resolved_by
      t.string :resolution_strategy
      t.text :rejection_reason

      t.timestamps
    end
  end
end
