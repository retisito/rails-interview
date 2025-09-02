class TodoItem < ApplicationRecord
  belongs_to :todo_list
  
  validates :description, presence: true, length: { minimum: 1, maximum: 500 }
  validates :completed, inclusion: { in: [true, false] }
  
  # Asignar valor por defecto para completed
  after_initialize :set_default_completed, if: :new_record?
  after_update :trigger_sync_if_needed, if: :should_trigger_sync?
  
  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }
  scope :needs_sync, -> { joins(:todo_list).where('todo_items.synced_at IS NULL OR todo_items.synced_at < todo_items.updated_at').where(todo_lists: { sync_enabled: true }) }

  def needs_sync?
    return false unless todo_list.sync_enabled?
    synced_at.nil? || synced_at < updated_at
  end

  def sync_status
    return 'disabled' unless todo_list.sync_enabled?
    return 'never_synced' if synced_at.nil?
    
    if synced_at >= updated_at
      'synced'
    else
      'needs_sync'
    end
  end

  def sync_status_badge
    case sync_status
    when 'synced'
      { text: 'Sincronizado', color: 'success', icon: 'check-circle' }
    when 'needs_sync'
      { text: 'Pendiente Sync', color: 'warning', icon: 'clock' }
    when 'never_synced'
      { text: 'No Sincronizado', color: 'info', icon: 'cloud-upload' }
    else
      { text: 'Sync Deshabilitado', color: 'secondary', icon: 'slash-circle' }
    end
  end

  def mark_synced!
    update_column(:synced_at, Time.current)
    Rails.logger.info "✅ TodoItem #{id} marked as synced"
  end

  def external_reference
    external_id.presence || "local_#{id}"
  end
  
  private
  
  def set_default_completed
    self.completed ||= false
  end

  def should_trigger_sync?
    todo_list.sync_enabled? && (saved_change_to_description? || saved_change_to_completed?)
  end

  def trigger_sync_if_needed
    # Marcar que el TodoList padre necesita sincronización
    Rails.logger.info "📝 TodoItem #{id} changed, marking TodoList for sync"
    
    # Opcional: disparar sync automático para cambios críticos
    if saved_change_to_completed? && completed?
      Rails.logger.info "🎯 TodoItem #{id} completed, considering immediate sync"
      # Aquí se podría disparar un sync inmediato si se desea
    end
  end
end
