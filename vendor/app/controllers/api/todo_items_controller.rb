module Api
  class TodoItemsController < BaseController
    before_action :set_todo_list
    before_action :set_todo_item, only: [:show, :update, :destroy]

    # GET /api/todolists/:todo_list_id/todos
    def index
      @todo_items = @todo_list.todo_items
      respond_to :json
    end

    # GET /api/todolists/:todo_list_id/todos/:id
    def show
      respond_to :json
    end

    # POST /api/todolists/:todo_list_id/todos
    def create
      @todo_item = @todo_list.todo_items.build(todo_item_params)

      if @todo_item.save
        render :show, status: :created
      else
        render json: { errors: @todo_item.errors }, status: :unprocessable_entity
      end
    end

    # PUT/PATCH /api/todolists/:todo_list_id/todos/:id
    def update
      if @todo_item.update(todo_item_params)
        render :show, status: :ok
      else
        render json: { errors: @todo_item.errors }, status: :unprocessable_entity
      end
    end

    # DELETE /api/todolists/:todo_list_id/todos/:id
    def destroy
      @todo_item.destroy
      head :no_content
    end

    private

    def set_todo_list
      @todo_list = TodoList.find(params[:todo_list_id])
    end

    def set_todo_item
      @todo_item = @todo_list.todo_items.find(params[:id])
    end

    def todo_item_params
      params.require(:todo_item).permit(:description, :completed)
    end
  end
end
