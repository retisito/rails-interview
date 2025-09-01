class TodoItemsController < ApplicationController
  before_action :set_todo_list
  before_action :set_todo_item, only: [:show, :edit, :update, :destroy, :toggle]

  # GET /todolists/:todo_list_id/todo_items
  def index
    @todo_items = @todo_list.todo_items.order(:created_at)
  end

  # GET /todolists/:todo_list_id/todo_items/:id
  def show
  end

  # GET /todolists/:todo_list_id/todo_items/new
  def new
    @todo_item = @todo_list.todo_items.build
  end

  # POST /todolists/:todo_list_id/todo_items
  def create
    @todo_item = @todo_list.todo_items.build(todo_item_params)

    if @todo_item.save
      redirect_to @todo_list, notice: 'Tarea creada exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /todolists/:todo_list_id/todo_items/:id/edit
  def edit
  end

  # PUT/PATCH /todolists/:todo_list_id/todo_items/:id
  def update
    if @todo_item.update(todo_item_params)
      redirect_to @todo_list, notice: 'Tarea actualizada exitosamente.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /todolists/:todo_list_id/todo_items/:id
  def destroy
    @todo_item.destroy
    redirect_to @todo_list, notice: 'Tarea eliminada exitosamente.'
  end

  # PATCH /todolists/:todo_list_id/todo_items/:id/toggle
  def toggle
    @todo_item.update(completed: !@todo_item.completed)
    redirect_to @todo_list, notice: 'Estado de tarea actualizado.'
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
