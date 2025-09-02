class TodoList < ApplicationRecord
  has_many :todo_items, dependent: :destroy
  has_many :sync_sessions, dependent: :destroy
  
  validates :name, presence: true, length: { minimum: 1, maximum: 255 }
  
  # Campos para sincronización
  # external_id: ID en la API externa
  # synced_at: Última vez que se sincronizó
  # sync_enabled: Si está habilitada la sincronización
  
  # Scopes para sincronización
  scope :sync_enabled, -> { where(sync_enabled: true) }
  scope :needs_sync, -> { where('synced_at IS NULL OR synced_at < updated_at') }
  
  # Callbacks
  after_update :mark_for_sync, if: :should_trigger_sync?
  
  def sync_enabled?
    sync_enabled == true
  end
  
  def needs_sync?
    return false unless sync_enabled?
    synced_at.nil? || synced_at < updated_at
  end
  
  def last_sync_session
    sync_sessions.recent.first
  end
  
  def sync_status
    return 'disabled' unless sync_enabled?
    return 'never_synced' if synced_at.nil?
    
    last_session = last_sync_session
    return 'no_sessions' unless last_session
    
    case last_session.status
    when 'completed'
      needs_sync? ? 'needs_sync' : 'synced'
    when 'running'
      'syncing'
    when 'failed'
      'sync_failed'
    else
      'unknown'
    end
  end
  
  def sync_status_color
    case sync_status
    when 'synced'
      'success'
    when 'syncing'
      'info'
    when 'needs_sync'
      'warning'
    when 'sync_failed', 'disabled'
      'danger'
    else
      'secondary'
    end
  end
  
  def sync_status_icon
    case sync_status
    when 'synced'
      'check-circle-fill'
    when 'syncing'
      'arrow-repeat'
    when 'needs_sync'
      'exclamation-triangle-fill'
    when 'sync_failed'
      'x-circle-fill'
    when 'disabled'
      'slash-circle'
    else
      'question-circle'
    end
  end
  
  def trigger_sync!(strategy: 'incremental_sync', conflict_resolution: 'last_write_wins')
    return false unless sync_enabled?
    
    Rails.logger.info "🔄 Triggering sync for TodoList #{id} with strategy: #{strategy}"
    
    BidirectionalSyncJob.perform_later(
      id,
      sync_strategy: strategy,
      conflict_resolution_strategy: conflict_resolution
    )
    
    true
  end
  
  def enable_sync!(external_id: nil)
    update!(
      sync_enabled: true,
      external_id: external_id || generate_external_id
    )
    
    Rails.logger.info "✅ Sync enabled for TodoList #{id} with external_id: #{self.external_id}"
  end
  
  def disable_sync!
    update!(sync_enabled: false)
    Rails.logger.info "❌ Sync disabled for TodoList #{id}"
  end
  
  def sync_stats
    {
      status: sync_status,
      last_synced: synced_at&.strftime("%Y-%m-%d %H:%M:%S"),
      total_sessions: sync_sessions.count,
      successful_sessions: sync_sessions.completed.count,
      failed_sessions: sync_sessions.failed.count,
      average_duration: sync_sessions.average_duration,
      needs_sync: needs_sync?
    }
  end
  
  private
  
  def should_trigger_sync?
    sync_enabled? && saved_change_to_name?
  end
  
  def mark_for_sync
    # Marcar que necesita sincronización pero no disparar automáticamente
    # para evitar loops infinitos
    Rails.logger.info "📝 TodoList #{id} marked for sync due to updates"
  end
  
  def generate_external_id
    "todolist_#{id}_#{SecureRandom.hex(4)}"
  end
end