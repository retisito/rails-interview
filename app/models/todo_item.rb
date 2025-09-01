class TodoItem < ApplicationRecord
  belongs_to :todo_list
  
  validates :description, presence: true, length: { minimum: 1, maximum: 500 }
  validates :completed, inclusion: { in: [true, false] }
  
  # Asignar valor por defecto para completed
  after_initialize :set_default_completed, if: :new_record?
  
  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }
  
  private
  
  def set_default_completed
    self.completed ||= false
  end
end
