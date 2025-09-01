class AutoCompleteBatchJob < ApplicationJob
  queue_as :default

  def perform(todo_list_id, item_ids, delay_seconds = 0)
    # Delay inicial si se especifica
    sleep(delay_seconds) if delay_seconds > 0
    
    Rails.logger.info "🎯 Starting batch completion for #{item_ids.count} items (TodoList #{todo_list_id})"
    
    todo_list = TodoList.find(todo_list_id)
    items = todo_list.todo_items.where(id: item_ids, completed: false)
    
    completed_count = 0
    items.each do |item|
      if item.update(completed: true)
        completed_count += 1
        Rails.logger.info "✅ Batch completed: #{item.description}"
        
        # Pequeño delay para simular procesamiento
        sleep(0.3)
      else
        Rails.logger.error "❌ Failed to complete: #{item.description}"
      end
    end
    
    Rails.logger.info "📦 Batch completion finished! Completed #{completed_count}/#{items.count} items"
    
    completed_count
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "❌ TodoList or items not found: #{e.message}"
    raise e
  rescue StandardError => e
    Rails.logger.error "❌ Batch completion failed: #{e.message}"
    raise e
  end
end
