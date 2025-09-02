# frozen_string_literal: true

# BidirectionalSyncJob - Job para sincronización bidireccional
# Implementa el patrón de sincronización del Plan de Acción Crunchloop
class BidirectionalSyncJob < ApplicationJob
  queue_as :sync
  
  # Retry configuration con backoff exponencial
  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  retry_on ExternalApiClient::RateLimitError, wait: 30.seconds, attempts: 3
  retry_on ExternalApiClient::ServerError, wait: 1.minute, attempts: 3
  
  # No retry para errores de autenticación
  discard_on ExternalApiClient::AuthenticationError
  
  # Callbacks
  before_perform :log_job_start
  after_perform :log_job_completion
  around_perform :measure_performance
  
  def perform(todo_list_id, sync_strategy: 'incremental_sync', conflict_resolution_strategy: 'last_write_wins', session_id: nil)
    @todo_list = TodoList.find(todo_list_id)
    @sync_strategy = sync_strategy
    @conflict_resolution_strategy = conflict_resolution_strategy
    @session_id = session_id || generate_session_id
    
    Rails.logger.info "🔄 Starting BidirectionalSyncJob for TodoList #{@todo_list.id}"
    Rails.logger.info "📊 Strategy: #{@sync_strategy}, Conflict Resolution: #{@conflict_resolution_strategy}"
    
    # Verificar conectividad con API externa
    verify_external_api_connectivity
    
    # Crear instancia del motor de sincronización
    sync_engine = SyncEngine.new(
      todo_list: @todo_list,
      external_api_client: ExternalApiClient.new,
      sync_strategy: @sync_strategy,
      conflict_resolution_strategy: @conflict_resolution_strategy
    )
    
    # Ejecutar sincronización bidireccional
    sync_results = sync_engine.perform_bidirectional_sync
    
    # Broadcast resultados en tiempo real
    broadcast_sync_completion(sync_results)
    
    # Auto-resolver conflictos si es posible
    auto_resolve_conflicts if sync_results[:conflicts_resolved] > 0
    
    # Programar próxima sincronización si es necesaria
    schedule_next_sync if should_schedule_next_sync?
    
    Rails.logger.info "✅ BidirectionalSyncJob completed successfully"
    sync_results
    
  rescue => e
    Rails.logger.error "❌ BidirectionalSyncJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    # Broadcast error
    broadcast_sync_error(e)
    
    # Re-raise para activar retry logic
    raise
  end
  
  private
  
  def verify_external_api_connectivity
    Rails.logger.info "🌐 Verifying external API connectivity"
    
    client = ExternalApiClient.new
    health_status = client.health_check
    
    Rails.logger.info "✅ External API is healthy: #{health_status['status']}"
    
    # Broadcast health status
    broadcast_api_health_status(health_status)
    
  rescue => e
    Rails.logger.error "❌ External API connectivity check failed: #{e.message}"
    raise ExternalApiClient::ApiError, "External API is not available: #{e.message}"
  end
  
  def broadcast_sync_completion(sync_results)
    Rails.logger.info "📡 Broadcasting sync completion results"
    
    # Broadcast via Turbo Streams
    Turbo::StreamsChannel.broadcast_replace_to(
      "sync_status_#{@todo_list.id}",
      target: "sync_results",
      partial: "sync_sessions/sync_results",
      locals: { 
        results: sync_results,
        todo_list: @todo_list,
        session_id: @session_id
      }
    )
    
    # También broadcast a canal general de sincronización
    Turbo::StreamsChannel.broadcast_append_to(
      "sync_notifications",
      target: "sync_notifications_list",
      partial: "shared/sync_notification",
      locals: {
        type: 'success',
        message: "Sincronización completada para '#{@todo_list.name}'",
        details: sync_results,
        timestamp: Time.current
      }
    )
  end
  
  def broadcast_sync_error(error)
    Rails.logger.info "📡 Broadcasting sync error"
    
    Turbo::StreamsChannel.broadcast_replace_to(
      "sync_status_#{@todo_list.id}",
      target: "sync_error",
      partial: "shared/error_message",
      locals: {
        error: error,
        context: "Sincronización de '#{@todo_list.name}'"
      }
    )
    
    Turbo::StreamsChannel.broadcast_append_to(
      "sync_notifications",
      target: "sync_notifications_list",
      partial: "shared/sync_notification",
      locals: {
        type: 'error',
        message: "Error en sincronización de '#{@todo_list.name}'",
        details: { error: error.message },
        timestamp: Time.current
      }
    )
  end
  
  def broadcast_api_health_status(health_status)
    Turbo::StreamsChannel.broadcast_replace_to(
      "api_health_status",
      target: "external_api_status",
      partial: "shared/api_health_status",
      locals: { health_status: health_status }
    )
  end
  
  def auto_resolve_conflicts
    Rails.logger.info "🤖 Attempting auto-resolution of conflicts"
    
    # Buscar tareas de resolución de conflictos pendientes para esta lista
    conflict_tasks = ConflictResolutionTask.joins(:sync_session)
                                          .where(sync_sessions: { todo_list: @todo_list })
                                          .pending
    
    auto_resolved_count = 0
    
    conflict_tasks.find_each do |task|
      if task.attempt_auto_resolution
        auto_resolved_count += 1
      end
    end
    
    if auto_resolved_count > 0
      Rails.logger.info "✅ Auto-resolved #{auto_resolved_count} conflicts"
      
      # Broadcast auto-resolution results
      Turbo::StreamsChannel.broadcast_append_to(
        "sync_notifications",
        target: "sync_notifications_list",
        partial: "shared/sync_notification",
        locals: {
          type: 'info',
          message: "#{auto_resolved_count} conflictos resueltos automáticamente",
          details: { auto_resolved: auto_resolved_count },
          timestamp: Time.current
        }
      )
    end
  end
  
  def should_schedule_next_sync?
    # Lógica para determinar si programar próxima sincronización
    case @sync_strategy
    when 'real_time_sync'
      false # Real-time no necesita programación
    when 'incremental_sync'
      true  # Programar sync incremental cada hora
    when 'batch_sync'
      true  # Programar batch sync cada 4 horas
    when 'full_sync'
      false # Full sync se ejecuta manualmente
    else
      false
    end
  end
  
  def schedule_next_sync
    delay = case @sync_strategy
            when 'incremental_sync'
              1.hour
            when 'batch_sync'
              4.hours
            else
              1.hour
            end
    
    Rails.logger.info "⏰ Scheduling next sync in #{delay / 1.hour} hours"
    
    BidirectionalSyncJob.set(wait: delay).perform_later(
      @todo_list.id,
      sync_strategy: @sync_strategy,
      conflict_resolution_strategy: @conflict_resolution_strategy
    )
  end
  
  def generate_session_id
    "sync_#{Time.current.to_i}_#{SecureRandom.hex(4)}"
  end
  
  def log_job_start
    Rails.logger.info "🚀" * 40
    Rails.logger.info "🚀 INICIANDO SINCRONIZACIÓN BIDIRECCIONAL"
    Rails.logger.info "📋 TodoList: #{@todo_list.name} (ID: #{@todo_list.id})"
    Rails.logger.info "🔧 Estrategia: #{@sync_strategy}"
    Rails.logger.info "🤝 Resolución de Conflictos: #{@conflict_resolution_strategy}"
    Rails.logger.info "🆔 Session ID: #{@session_id}"
    Rails.logger.info "⏰ Iniciado: #{Time.current}"
    Rails.logger.info "🚀" * 40
  end
  
  def log_job_completion
    Rails.logger.info "🎉" * 40
    Rails.logger.info "🎉 SINCRONIZACIÓN BIDIRECCIONAL COMPLETADA"
    Rails.logger.info "📋 TodoList: #{@todo_list.name} (ID: #{@todo_list.id})"
    Rails.logger.info "⏰ Completado: #{Time.current}"
    Rails.logger.info "🎉" * 40
  end
  
  def measure_performance
    start_time = Time.current
    
    yield
    
    duration = Time.current - start_time
    Rails.logger.info "⏱️ Sync duration: #{duration.round(2)} seconds"
    
    # Registrar métricas de performance
    SyncPerformanceMetric.create!(
      todo_list: @todo_list,
      sync_strategy: @sync_strategy,
      duration: duration,
      timestamp: start_time
    )
  end
end
