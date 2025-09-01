class AddTimestampsToTodoLists < ActiveRecord::Migration[7.0]
  def up
    add_timestamps :todo_lists, null: true
    
    # Update existing records with current timestamp
    current_time = Time.current
    TodoList.update_all(created_at: current_time, updated_at: current_time)
    
    # Make columns non-null after setting values
    change_column_null :todo_lists, :created_at, false
    change_column_null :todo_lists, :updated_at, false
  end

  def down
    remove_timestamps :todo_lists
  end
end
