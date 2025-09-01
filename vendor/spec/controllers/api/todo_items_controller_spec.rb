require 'rails_helper'

RSpec.describe Api::TodoItemsController, type: :controller do
  render_views

  let!(:todo_list) { TodoList.create(name: 'Test List') }

  describe 'GET index' do
    let!(:todo_item1) { todo_list.todo_items.create(description: 'Item 1', completed: false) }
    let!(:todo_item2) { todo_list.todo_items.create(description: 'Item 2', completed: true) }

    it 'returns a success code' do
      get :index, params: { todo_list_id: todo_list.id }, format: :json
      expect(response.status).to eq(200)
    end

    it 'includes all todo items for the list' do
      get :index, params: { todo_list_id: todo_list.id }, format: :json
      todo_items = JSON.parse(response.body)

      aggregate_failures 'includes all todo items' do
        expect(todo_items.count).to eq(2)
        expect(todo_items[0].keys).to match_array(['id', 'description', 'completed'])
        expect(todo_items.map { |ti| ti['id'] }).to match_array([todo_item1.id, todo_item2.id])
      end
    end
  end

  describe 'GET show' do
    let!(:todo_item) { todo_list.todo_items.create(description: 'Test Item', completed: false) }

    context 'when todo item exists' do
      it 'returns the todo item' do
        get :show, params: { todo_list_id: todo_list.id, id: todo_item.id }, format: :json
        
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result['id']).to eq(todo_item.id)
        expect(result['description']).to eq('Test Item')
        expect(result['completed']).to eq(false)
      end
    end

    context 'when todo item does not exist' do
      it 'returns 404' do
        expect {
          get :show, params: { todo_list_id: todo_list.id, id: 999 }, format: :json
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'POST create' do
    context 'with valid parameters' do
      let(:valid_params) { 
        { 
          todo_list_id: todo_list.id, 
          todo_item: { description: 'New Item', completed: false } 
        } 
      }

      it 'creates a new todo item' do
        expect {
          post :create, params: valid_params, format: :json
        }.to change(TodoItem, :count).by(1)
      end

      it 'creates the item for the correct todo list' do
        post :create, params: valid_params, format: :json
        
        expect(response.status).to eq(201)
        result = JSON.parse(response.body)
        expect(result['description']).to eq('New Item')
        expect(TodoItem.last.todo_list).to eq(todo_list)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { 
        { 
          todo_list_id: todo_list.id, 
          todo_item: { description: '', completed: false } 
        } 
      }

      it 'does not create a todo item' do
        expect {
          post :create, params: invalid_params, format: :json
        }.not_to change(TodoItem, :count)
      end

      it 'returns validation errors' do
        post :create, params: invalid_params, format: :json
        
        expect(response.status).to eq(422)
        result = JSON.parse(response.body)
        expect(result['errors']).to be_present
      end
    end
  end

  describe 'PUT update' do
    let!(:todo_item) { todo_list.todo_items.create(description: 'Original', completed: false) }

    context 'with valid parameters' do
      let(:valid_params) { 
        { 
          todo_list_id: todo_list.id, 
          id: todo_item.id, 
          todo_item: { description: 'Updated', completed: true } 
        } 
      }

      it 'updates the todo item' do
        put :update, params: valid_params, format: :json
        
        expect(response.status).to eq(200)
        todo_item.reload
        expect(todo_item.description).to eq('Updated')
        expect(todo_item.completed).to eq(true)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { 
        { 
          todo_list_id: todo_list.id, 
          id: todo_item.id, 
          todo_item: { description: '' } 
        } 
      }

      it 'returns validation errors' do
        put :update, params: invalid_params, format: :json
        
        expect(response.status).to eq(422)
        result = JSON.parse(response.body)
        expect(result['errors']).to be_present
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:todo_item) { todo_list.todo_items.create(description: 'To be deleted', completed: false) }

    it 'deletes the todo item' do
      expect {
        delete :destroy, params: { todo_list_id: todo_list.id, id: todo_item.id }, format: :json
      }.to change(TodoItem, :count).by(-1)
    end

    it 'returns no content status' do
      delete :destroy, params: { todo_list_id: todo_list.id, id: todo_item.id }, format: :json
      expect(response.status).to eq(204)
    end
  end
end
