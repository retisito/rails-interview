require 'rails_helper'

RSpec.describe Api::TodoListsController, type: :controller do
  render_views

  describe 'GET index' do
    let!(:todo_list1) { TodoList.create(name: 'Setup RoR project') }
    let!(:todo_list2) { TodoList.create(name: 'Deploy application') }

    context 'when format is HTML' do
      it 'raises a routing error' do
        expect {
          get :index
        }.to raise_error(ActionController::RoutingError, 'Not supported format')
      end
    end

    context 'when format is JSON' do
      it 'returns a success code' do
        get :index, format: :json
        expect(response.status).to eq(200)
      end

      it 'includes all todo list records' do
        get :index, format: :json
        todo_lists = JSON.parse(response.body)

        aggregate_failures 'includes the id, name, and timestamps' do
          expect(todo_lists.count).to eq(2)
          expect(todo_lists[0].keys).to match_array(['id', 'name', 'created_at', 'updated_at'])
          expect(todo_lists.map { |tl| tl['id'] }).to match_array([todo_list1.id, todo_list2.id])
        end
      end
    end
  end

  describe 'GET show' do
    let!(:todo_list) { TodoList.create(name: 'Test List') }

    context 'when todo list exists' do
      it 'returns the todo list' do
        get :show, params: { id: todo_list.id }, format: :json
        
        expect(response.status).to eq(200)
        result = JSON.parse(response.body)
        expect(result['id']).to eq(todo_list.id)
        expect(result['name']).to eq('Test List')
      end
    end

    context 'when todo list does not exist' do
      it 'returns 404' do
        expect {
          get :show, params: { id: 999 }, format: :json
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'POST create' do
    context 'with valid parameters' do
      let(:valid_params) { { todo_list: { name: 'New Todo List' } } }

      it 'creates a new todo list' do
        expect {
          post :create, params: valid_params, format: :json
        }.to change(TodoList, :count).by(1)
      end

      it 'returns the created todo list' do
        post :create, params: valid_params, format: :json
        
        expect(response.status).to eq(201)
        result = JSON.parse(response.body)
        expect(result['name']).to eq('New Todo List')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { { todo_list: { name: '' } } }

      it 'does not create a todo list' do
        expect {
          post :create, params: invalid_params, format: :json
        }.not_to change(TodoList, :count)
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
    let!(:todo_list) { TodoList.create(name: 'Original Name') }

    context 'with valid parameters' do
      let(:valid_params) { { id: todo_list.id, todo_list: { name: 'Updated Name' } } }

      it 'updates the todo list' do
        put :update, params: valid_params, format: :json
        
        expect(response.status).to eq(200)
        todo_list.reload
        expect(todo_list.name).to eq('Updated Name')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { { id: todo_list.id, todo_list: { name: '' } } }

      it 'returns validation errors' do
        put :update, params: invalid_params, format: :json
        
        expect(response.status).to eq(422)
        result = JSON.parse(response.body)
        expect(result['errors']).to be_present
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:todo_list) { TodoList.create(name: 'To be deleted') }

    it 'deletes the todo list' do
      expect {
        delete :destroy, params: { id: todo_list.id }, format: :json
      }.to change(TodoList, :count).by(-1)
    end

    it 'returns no content status' do
      delete :destroy, params: { id: todo_list.id }, format: :json
      expect(response.status).to eq(204)
    end
  end
end
