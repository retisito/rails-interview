module Api
  class TodoListsController < BaseController
    before_action :set_todo_list, only: [:show, :update, :destroy, :auto_complete]

    # GET /api/todolists
    def index
      @todo_lists = TodoList.all
      respond_to :json
    end

    # GET /api/todolists/:id
    def show
      respond_to :json
    end

    # POST /api/todolists
    def create
      @todo_list = TodoList.new(todo_list_params)

      if @todo_list.save
        render :show, status: :created
      else
        render json: { errors: @todo_list.errors }, status: :unprocessable_entity
      end
    end

    # PUT/PATCH /api/todolists/:id
    def update
      if @todo_list.update(todo_list_params)
        render :show, status: :ok
      else
        render json: { errors: @todo_list.errors }, status: :unprocessable_entity
      end
    end

    # DELETE /api/todolists/:id
    def destroy
      @todo_list.destroy
      head :no_content
    end

    # POST /api/todolists/:id/auto_complete
    def auto_complete
      delay_seconds = params[:delay_seconds]&.to_i || 5
      mode = params[:mode] || 'simple'
      session_id = params[:session_id]
      
      case mode
      when 'simple'
        result = AutoCompletionService.schedule_completion(@todo_list, delay_seconds, session_id)
      when 'random'
        min_delay = params[:min_delay]&.to_i || 5
        max_delay = params[:max_delay]&.to_i || 30
        result = AutoCompletionService.schedule_completion_with_random_delay(@todo_list, min_delay, max_delay, session_id)
      when 'batch'
        batch_size = params[:batch_size]&.to_i || 3
        delay_between = params[:delay_between_batches]&.to_i || 10
        result = AutoCompletionService.schedule_batch_completion(@todo_list, batch_size, delay_between)
      else
        render json: { error: "Invalid mode. Use 'simple', 'random', or 'batch'" }, status: :bad_request
        return
      end

      render json: {
        message: "Auto-completion scheduled successfully",
        todo_list: {
          id: @todo_list.id,
          name: @todo_list.name,
          pending_items_count: @todo_list.todo_items.pending.count
        },
        job_details: result
      }, status: :accepted
    rescue StandardError => e
      render json: { 
        error: "Failed to schedule auto-completion", 
        details: e.message 
      }, status: :unprocessable_entity
    end

    private

    def set_todo_list
      @todo_list = TodoList.find(params[:id])
    end

    def todo_list_params
      params.require(:todo_list).permit(:name)
    end
  end
end
