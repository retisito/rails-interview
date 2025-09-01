class TodoList < ApplicationRecord
  has_many :todo_items, dependent: :destroy
  
  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
end