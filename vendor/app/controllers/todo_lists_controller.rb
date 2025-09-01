class TodoListsController < ApplicationController
  before_action :set_todo_list, only: [:show, :edit, :update, :destroy, :start_progressive_completion, :progress]

  # GET /todolists
  def index
    @todo_lists = TodoList.all
  end

  # GET /todolists/:id
  def show
    @todo_items = @todo_list.todo_items.order(:created_at)
    @session_id = params[:session_id] # Para Turbo Streams si viene de procesamiento
  end

  # GET /todolists/new
  def new
    @todo_list = TodoList.new
  end

  # POST /todolists
  def create
    @todo_list = TodoList.new(todo_list_params)

    if @todo_list.save
      redirect_to @todo_list, notice: 'Lista creada exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /todolists/:id/edit
  def edit
  end

  # PUT/PATCH /todolists/:id
  def update
    if @todo_list.update(todo_list_params)
      redirect_to @todo_list, notice: 'Lista actualizada exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /todolists/:id
  def destroy
    @todo_list.destroy
    redirect_to todo_lists_path, notice: 'Lista eliminada exitosamente.'
  end

  # POST /todolists/:id/start_progressive_completion
  def start_progressive_completion
    session_id = generate_session_id
    
    # Verificar que hay tareas pendientes
    pending_count = @todo_list.todo_items.pending.count
    
    if pending_count == 0
      respond_to do |format|
        format.html { redirect_to @todo_list, alert: "No hay tareas pendientes para completar." }
        format.json { render json: { error: "No hay tareas pendientes" }, status: :unprocessable_entity }
      end
      return
    end
    
    # Programar el job
    ProgressiveCompletionJob.perform_later(@todo_list.id, session_id)
    
    Rails.logger.info "🚀 Started progressive completion job for TodoList #{@todo_list.id} (Session: #{session_id})"
    
    respond_to do |format|
      format.html { 
        redirect_to todo_list_path(@todo_list, session_id: session_id), 
                    notice: "Procesamiento iniciado para #{pending_count} tareas"
      }
      format.json { 
        render json: { 
          session_id: session_id, 
          message: "Procesamiento iniciado",
          pending_count: pending_count
        }
      }
    end
  end
  
  # GET /todolists/:id/progress
  def progress
    @session_id = params[:session_id] || generate_session_id
    
    # Estado inicial del progreso
    @initial_progress = {
      percentage: 0,
      message: "Preparando procesamiento...",
      status: 'initial'
    }
  end
  
  # GET /todolists/:id/test_cable
  def test_cable
    test_session = "test_#{Time.now.to_i}"
    
    # Test broadcast
    html = ApplicationController.render(
      partial: "shared/progress_bar",
      locals: {
        percentage: 50,
        message: "Test broadcast from Action Cable",
        status: 'processing',
        current_item: 1,
        total_items: 2
      }
    )
    
    Turbo::StreamsChannel.broadcast_replace_to(
      "progress_#{test_session}",
      target: "progress-container",
      html: html
    )
    
    render json: { 
      message: "Test broadcast sent", 
      session_id: test_session,
      channel: "progress_#{test_session}"
    }
  end

  private

  def set_todo_list
    @todo_list = TodoList.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to todo_lists_path, alert: "Lista no encontrada."
  end

  def todo_list_params
    params.require(:todo_list).permit(:name)
  end

  def generate_session_id
    "#{Time.current.to_i}_#{SecureRandom.hex(4)}"
  end
end
