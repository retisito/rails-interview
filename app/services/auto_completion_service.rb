class AutoCompletionService
  class << self
    # Programa el completado automático de una lista
    def schedule_completion(todo_list, delay_seconds = 5, session_id = nil)
      job = AutoCompleteTodoItemsJob.perform_later(todo_list.id, delay_seconds, session_id)
      
      Rails.logger.info "📅 Scheduled auto-completion for TodoList #{todo_list.id} (Job ID: #{job.job_id})"
      
      {
        job_id: job.job_id,
        todo_list_id: todo_list.id,
        delay_seconds: delay_seconds,
        scheduled_at: Time.current,
        estimated_completion_at: Time.current + delay_seconds.seconds
      }
    end

    # Programa completado automático con diferentes delays
    def schedule_completion_with_random_delay(todo_list, min_delay = 5, max_delay = 30, session_id = nil)
      random_delay = rand(min_delay..max_delay)
      schedule_completion(todo_list, random_delay, session_id)
    end

    # Programa completado en lotes (por grupos de tareas)
    def schedule_batch_completion(todo_list, batch_size = 3, delay_between_batches = 10)
      pending_items = todo_list.todo_items.pending
      
      if pending_items.empty?
        Rails.logger.info "📋 No pending items found for TodoList #{todo_list.id}"
        return { message: "No pending items to complete" }
      end

      batches = pending_items.in_batches(of: batch_size)
      jobs = []
      
      batches.each_with_index do |batch, index|
        delay = delay_between_batches * index
        
        job = AutoCompleteBatchJob.perform_later(
          todo_list.id, 
          batch.pluck(:id), 
          delay
        )
        
        jobs << {
          job_id: job.job_id,
          batch_number: index + 1,
          item_ids: batch.pluck(:id),
          delay_seconds: delay,
          scheduled_at: Time.current + delay.seconds
        }
      end
      
      Rails.logger.info "📦 Scheduled #{jobs.count} batch jobs for TodoList #{todo_list.id}"
      
      {
        todo_list_id: todo_list.id,
        total_batches: jobs.count,
        total_items: pending_items.count,
        jobs: jobs
      }
    end

    # Obtener estadísticas de jobs en cola
    def get_job_stats
      stats = Sidekiq::Stats.new
      
      {
        processed: stats.processed,
        failed: stats.failed,
        busy: stats.workers_size,
        enqueued: stats.enqueued,
        scheduled: stats.scheduled_size,
        retries: stats.retry_size,
        dead: stats.dead_size,
        queues: stats.queues
      }
    end

    # Cancelar jobs programados para una lista específica
    def cancel_scheduled_jobs(todo_list_id)
      # Esto requiere Sidekiq Pro para funcionar completamente
      # En la versión gratuita, podemos marcar como cancelados
      
      Rails.logger.info "🚫 Attempting to cancel jobs for TodoList #{todo_list_id}"
      
      # Por ahora, solo logging - en producción usarías Sidekiq Pro
      # o implementarías tu propio sistema de cancelación
      
      { 
        message: "Job cancellation logged for TodoList #{todo_list_id}",
        note: "Actual cancellation requires Sidekiq Pro or custom implementation"
      }
    end
  end
end
