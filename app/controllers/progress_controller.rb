class ProgressController < ApplicationController
  # POST /todolists/:todo_list_id/start_progressive_completion
  def start_progressive_completion
    @todo_list = TodoList.find(params[:todo_list_id])
    session_id = generate_session_id
    
    # Verificar que hay tareas pendientes
    pending_count = @todo_list.todo_items.pending.count
    
    if pending_count == 0
      redirect_to @todo_list, alert: "No hay tareas pendientes para completar."
      return
    end
    
    # Programar el job
    ProgressiveCompletionJob.perform_later(@todo_list.id, session_id)
    
    Rails.logger.info "🚀 Started progressive completion job for TodoList #{@todo_list.id} (Session: #{session_id})"
    
    # Redirigir a la vista de progreso
    redirect_to progress_todo_list_path(@todo_list, session_id: session_id),
                notice: "Iniciando procesamiento de #{pending_count} tareas..."
  end
  
  # GET /todolists/:id/progress
  def show
    @todo_list = TodoList.find(params[:id])
    @session_id = params[:session_id] || generate_session_id
    
    # Estado inicial del progreso
    @initial_progress = {
      percentage: 0,
      message: "Preparando procesamiento...",
      status: 'initial'
    }
  end

  private

  def generate_session_id
    "#{Time.current.to_i}_#{SecureRandom.hex(4)}"
  end
end
