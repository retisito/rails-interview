class AutoCompleteTodoItemsJob < ApplicationJob
  queue_as :default

  def perform(todo_list_id, delay_seconds = 5, session_id = nil)
    # Simular delay de procesamiento
    Rails.logger.info "🚀 Starting auto-completion for TodoList #{todo_list_id} with #{delay_seconds}s delay"
    
    todo_list = TodoList.find(todo_list_id)
    pending_items = todo_list.todo_items.pending.to_a
    total_items = pending_items.count
    
    Rails.logger.info "📋 Found #{total_items} pending items to complete"
    
    # Broadcast estado inicial si tenemos session_id
    if session_id
      broadcast_progress(session_id, 0, "Iniciando proceso automático...", 0, total_items)
      sleep(delay_seconds)
      broadcast_progress(session_id, 5, "Procesando tareas pendientes...", 0, total_items)
    else
      sleep(delay_seconds)
    end
    
    # Completar todas las tareas pendientes
    completed_count = 0
    pending_items.each_with_index do |item, index|
      # Calcular progreso
      current_progress = ((index.to_f / total_items) * 85).round + 10 # 10-95%
      
      # Broadcast progreso antes de procesar
      if session_id
        broadcast_progress(session_id, current_progress, "Completando: #{item.description}", index + 1, total_items)
      end
      
      if item.update(completed: true)
        completed_count += 1
        Rails.logger.info "✅ Completed: #{item.description}"
        
        # Broadcast progreso después de completar
        final_item_progress = (((index + 1).to_f / total_items) * 85).round + 10
        if session_id
          broadcast_progress(session_id, final_item_progress, "Completado: #{item.description}", index + 1, total_items)
        end
        
        # Pequeño delay entre items para simular procesamiento
        sleep(0.5)
      else
        Rails.logger.error "❌ Failed to complete: #{item.description}"
      end
    end
    
    # Progreso final
    if session_id
      broadcast_completion(session_id, "¡Proceso completado! #{completed_count} tareas finalizadas.", 100)
    end
    
    Rails.logger.info "🎉 Auto-completion finished! Completed #{completed_count}/#{total_items} items"
    
    completed_count
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "❌ TodoList not found: #{e.message}"
    raise e
  rescue StandardError => e
    if session_id
      broadcast_error(session_id, "Error en el procesamiento: #{e.message}")
    end
    Rails.logger.error "❌ Auto-completion failed: #{e.message}"
    raise e
  end

  private

  def broadcast_progress(session_id, percentage, message, current_item, total_items)
    Turbo::StreamsChannel.broadcast_replace_to(
      "progress_#{session_id}",
      target: "progress-container",
      partial: "shared/progress_bar",
      locals: {
        percentage: percentage,
        message: message,
        current_item: current_item,
        total_items: total_items,
        status: 'processing'
      }
    )
  end

  def broadcast_completion(session_id, message, percentage)
    Turbo::StreamsChannel.broadcast_replace_to(
      "progress_#{session_id}",
      target: "progress-container", 
      partial: "shared/progress_bar",
      locals: {
        percentage: percentage,
        message: message,
        current_item: nil,
        total_items: nil,
        status: 'completed'
      }
    )
  end

  def broadcast_error(session_id, message)
    Turbo::StreamsChannel.broadcast_replace_to(
      "progress_#{session_id}",
      target: "progress-container",
      partial: "shared/progress_bar", 
      locals: {
        percentage: 0,
        message: message,
        current_item: nil,
        total_items: nil,
        status: 'error'
      }
    )
  end
end
