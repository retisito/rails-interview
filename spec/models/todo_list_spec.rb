require 'rails_helper'

RSpec.describe TodoList, type: :model do
  describe 'validations' do
    it 'is valid with a name' do
      todo_list = TodoList.new(name: 'Test List')
      expect(todo_list).to be_valid
    end

    it 'is invalid without a name' do
      todo_list = TodoList.new(name: nil)
      expect(todo_list).not_to be_valid
      expect(todo_list.errors[:name]).to include("can't be blank")
    end

    it 'is invalid with an empty name' do
      todo_list = TodoList.new(name: '')
      expect(todo_list).not_to be_valid
      expect(todo_list.errors[:name]).to include("can't be blank")
    end

    it 'is invalid with a name longer than 255 characters' do
      todo_list = TodoList.new(name: 'a' * 256)
      expect(todo_list).not_to be_valid
      expect(todo_list.errors[:name]).to include("is too long (maximum is 255 characters)")
    end
  end

  describe 'associations' do
    let(:todo_list) { TodoList.create(name: 'Test List') }

    it 'has many todo items' do
      item1 = todo_list.todo_items.create(description: 'Item 1', completed: false)
      item2 = todo_list.todo_items.create(description: 'Item 2', completed: true)

      expect(todo_list.todo_items.count).to eq(2)
      expect(todo_list.todo_items).to include(item1, item2)
    end

    it 'destroys associated todo items when deleted' do
      todo_list.todo_items.create(description: 'Item 1', completed: false)
      todo_list.todo_items.create(description: 'Item 2', completed: true)

      expect { todo_list.destroy }.to change(TodoItem, :count).by(-2)
    end
  end
end
