class ProgressiveCompletionJob < ApplicationJob
  queue_as :default

  def perform(todo_list_id, session_id)
    todo_list = TodoList.find(todo_list_id)
    pending_items = todo_list.todo_items.pending.to_a
    total_items = pending_items.count
    
    puts "\n" + "🚀"*40
    puts "🚀 INICIANDO PROCESAMIENTO PROGRESIVO"
    puts "📋 Total de tareas: #{total_items}"
    puts "🔑 Session ID: #{session_id}"
    puts "⏱️ Tiempo estimado: #{total_items * 2} segundos"
    puts "🚀"*40 + "\n"
    
    Rails.logger.info "🚀 Starting progressive completion for #{total_items} items (Session: #{session_id})"
    
    if total_items == 0
      puts "⚠️ NO HAY TAREAS PENDIENTES"
      broadcast_completion(session_id, "No hay tareas pendientes para completar", 100)
      return
    end

    # Broadcast inicial
    puts "📡 Enviando progreso inicial: 0%"
    broadcast_progress(session_id, 0, "Iniciando procesamiento...", 0, total_items)

    # Procesar cada tarea - EXACTAMENTE 2 segundos por tarea
    pending_items.each_with_index do |item, index|
      puts "\n" + "="*80
      puts "🔄 PROCESANDO TAREA #{index + 1}/#{total_items}"
      puts "📝 Descripción: #{item.description}"
      
      # Progreso al inicio de la tarea
      current_progress = ((index.to_f / total_items) * 100).round
      puts "📊 PROGRESO INICIAL: #{current_progress}% (#{index}/#{total_items} tareas completadas)"
      
      Rails.logger.info "🔄 Processing item #{index + 1}/#{total_items}: #{item.description} - #{current_progress}%"
      broadcast_progress(session_id, current_progress, "Procesando: #{item.description}", index, total_items)
      
      # ⏱️ EXACTAMENTE 2 segundos de procesamiento
      sleep(2)
      
      # Completar la tarea
      if item.update(completed: true)
        puts "✅ TAREA COMPLETADA: #{item.description}"
        Rails.logger.info "✅ Completed: #{item.description}"
        
        # ✨ BROADCAST para tachar la tarea en la lista
        broadcast_task_completed(session_id, item)
      else
        puts "❌ ERROR AL COMPLETAR: #{item.description}"
        Rails.logger.error "❌ Failed to complete: #{item.description}"
      end
      
      # Progreso después de completar
      final_progress = (((index + 1).to_f / total_items) * 100).round
      puts "🎯 PROGRESO FINAL: #{final_progress}% (#{index + 1}/#{total_items} tareas completadas)"
      puts "="*80 + "\n"
      
      Rails.logger.info "🎯 Progress updated: #{final_progress}% - Completed #{index + 1}/#{total_items}"
      broadcast_progress(session_id, final_progress, "Completado: #{item.description}", index + 1, total_items)
    end
    
    # Proceso completado
    puts "\n" + "🎉"*40
    puts "🎉 PROCESAMIENTO COMPLETADO AL 100%"
    puts "✅ Todas las #{total_items} tareas fueron completadas"
    puts "⏱️ Tiempo total: #{total_items * 2} segundos"
    puts "🎉"*40 + "\n"
    
    broadcast_completion(session_id, "¡Todas las tareas han sido completadas exitosamente! 🎉", 100)
    
    Rails.logger.info "🎉 Progressive completion finished! Completed #{total_items} items"
    
  rescue ActiveRecord::RecordNotFound => e
    broadcast_error(session_id, "Lista no encontrada: #{e.message}")
    Rails.logger.error "❌ TodoList not found: #{e.message}"
  rescue StandardError => e
    broadcast_error(session_id, "Error durante el procesamiento: #{e.message}")
    Rails.logger.error "❌ Progressive completion failed: #{e.message}"
  end

  private

  def broadcast_progress(session_id, percentage, message, current_item, total_items)
    begin
      Rails.logger.info "📡 Broadcasting progress: #{percentage}% - #{message} (#{current_item}/#{total_items})"
      
      html = ApplicationController.render(
        partial: "shared/progress_bar",
        locals: {
          percentage: percentage,
          message: message,
          current_item: current_item,
          total_items: total_items,
          status: 'processing'
        }
      )
      
      channel_name = "progress_#{session_id}"
      Rails.logger.info "📺 Sending to channel: #{channel_name}"
      
      Turbo::StreamsChannel.broadcast_replace_to(
        channel_name,
        target: "progress-container",
        html: html
      )
      
      Rails.logger.info "✅ Broadcast sent successfully"
    rescue => e
      Rails.logger.error "❌ Failed to broadcast progress: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def broadcast_completion(session_id, message, percentage)
    begin
      Rails.logger.info "🎉 Broadcasting completion: #{percentage}% - #{message}"
      
      html = ApplicationController.render(
        partial: "shared/progress_bar",
        locals: {
          percentage: percentage,
          message: message,
          current_item: nil,
          total_items: nil,
          status: 'completed'
        }
      )
      
      channel_name = "progress_#{session_id}"
      Rails.logger.info "📺 Sending completion to channel: #{channel_name}"
      
      Turbo::StreamsChannel.broadcast_replace_to(
        channel_name,
        target: "progress-container",
        html: html
      )
      
      Rails.logger.info "✅ Completion broadcast sent successfully"
    rescue => e
      Rails.logger.error "❌ Failed to broadcast completion: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def broadcast_error(session_id, message)
    begin
      html = ApplicationController.render(
        partial: "shared/progress_bar",
        locals: {
          percentage: 0,
          message: message,
          current_item: nil,
          total_items: nil,
          status: 'error'
        }
      )
      
      Turbo::StreamsChannel.broadcast_replace_to(
        "progress_#{session_id}",
        target: "progress-container",
        html: html
      )
    rescue => e
      Rails.logger.error "Failed to broadcast error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end

  def broadcast_task_completed(session_id, todo_item)
    begin
      Rails.logger.info "🎯 Broadcasting task completion for: #{todo_item.description}"
      
      # Renderizar el item de la lista actualizado
      html = ApplicationController.render(
        partial: "todo_lists/todo_item",
        locals: { todo_item: todo_item, todo_list: todo_item.todo_list }
      )
      
      Turbo::StreamsChannel.broadcast_replace_to(
        "progress_#{session_id}",
        target: "todo_item_#{todo_item.id}",
        html: html
      )
      
      Rails.logger.info "✅ Task completion broadcast sent successfully"
    rescue => e
      Rails.logger.error "❌ Failed to broadcast task completion: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
