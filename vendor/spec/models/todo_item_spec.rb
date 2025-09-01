require 'rails_helper'

RSpec.describe TodoItem, type: :model do
  let(:todo_list) { TodoList.create(name: 'Test List') }

  describe 'validations' do
    it 'is valid with valid attributes' do
      todo_item = TodoItem.new(description: 'Test Item', completed: false, todo_list: todo_list)
      expect(todo_item).to be_valid
    end

    it 'is invalid without a description' do
      todo_item = TodoItem.new(description: nil, completed: false, todo_list: todo_list)
      expect(todo_item).not_to be_valid
      expect(todo_item.errors[:description]).to include("can't be blank")
    end

    it 'is invalid with an empty description' do
      todo_item = TodoItem.new(description: '', completed: false, todo_list: todo_list)
      expect(todo_item).not_to be_valid
      expect(todo_item.errors[:description]).to include("can't be blank")
    end

    it 'is invalid with a description longer than 500 characters' do
      todo_item = TodoItem.new(description: 'a' * 501, completed: false, todo_list: todo_list)
      expect(todo_item).not_to be_valid
      expect(todo_item.errors[:description]).to include("is too long (maximum is 500 characters)")
    end

    it 'is invalid without a todo_list' do
      todo_item = TodoItem.new(description: 'Test Item', completed: false)
      expect(todo_item).not_to be_valid
      expect(todo_item.errors[:todo_list]).to include("must exist")
    end

    it 'validates completed is boolean' do
      todo_item = TodoItem.new(description: 'Test Item', completed: true, todo_list: todo_list)
      expect(todo_item).to be_valid

      todo_item.completed = false
      expect(todo_item).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a todo list' do
      todo_item = TodoItem.create(description: 'Test Item', completed: false, todo_list: todo_list)
      expect(todo_item.todo_list).to eq(todo_list)
    end
  end

  describe 'scopes' do
    let!(:completed_item) { todo_list.todo_items.create(description: 'Completed', completed: true) }
    let!(:pending_item) { todo_list.todo_items.create(description: 'Pending', completed: false) }

    it '.completed returns only completed items' do
      expect(TodoItem.completed).to include(completed_item)
      expect(TodoItem.completed).not_to include(pending_item)
    end

    it '.pending returns only pending items' do
      expect(TodoItem.pending).to include(pending_item)
      expect(TodoItem.pending).not_to include(completed_item)
    end
  end
end
