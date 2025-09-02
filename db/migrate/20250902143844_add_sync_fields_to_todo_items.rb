class AddSyncFieldsToTodoItems < ActiveRecord::Migration[7.0]
  def change
    add_column :todo_items, :external_id, :string
    add_column :todo_items, :synced_at, :datetime
  end
end
