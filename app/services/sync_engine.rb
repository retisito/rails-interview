# frozen_string_literal: true

# SyncEngine - Motor de Sincronización Bidireccional
# Basado en el Plan de Acción Crunchloop - Opción 4: Rails Híbrido Inteligente
class SyncEngine
  include ActiveModel::Model
  
  attr_accessor :todo_list, :external_api_client, :sync_strategy, :conflict_resolution_strategy
  
  # Estrategias de sincronización disponibles
  SYNC_STRATEGIES = %w[
    full_sync
    incremental_sync
    real_time_sync
    batch_sync
  ].freeze
  
  # Estrategias de resolución de conflictos
  CONFLICT_STRATEGIES = %w[
    last_write_wins
    merge_changes
    manual_resolution
    external_priority
    local_priority
  ].freeze
  
  def initialize(todo_list:, external_api_client: nil, sync_strategy: 'incremental_sync', conflict_resolution_strategy: 'last_write_wins')
    @todo_list = todo_list
    @external_api_client = external_api_client || ExternalApiClient.new
    @sync_strategy = sync_strategy
    @conflict_resolution_strategy = conflict_resolution_strategy
    @sync_session = SyncSession.create!(
      todo_list: todo_list,
      strategy: sync_strategy,
      status: 'initiated',
      started_at: Time.current
    )
  end
  
  # Método principal de sincronización bidireccional
  def perform_bidirectional_sync
    Rails.logger.info "🔄 Starting bidirectional sync for TodoList #{@todo_list.id}"
    Rails.logger.info "📊 Strategy: #{@sync_strategy}, Conflict Resolution: #{@conflict_resolution_strategy}"
    
    begin
      @sync_session.update!(status: 'running')
      
      # Fase 1: Obtener cambios locales y remotos
      local_changes = detect_local_changes
      remote_changes = fetch_remote_changes
      
      Rails.logger.info "📈 Local changes: #{local_changes.count}, Remote changes: #{remote_changes.count}"
      
      # Fase 2: Detectar y resolver conflictos
      conflicts = detect_conflicts(local_changes, remote_changes)
      resolved_changes = resolve_conflicts(conflicts) if conflicts.any?
      
      # Fase 3: Aplicar cambios
      sync_results = apply_sync_changes(local_changes, remote_changes, resolved_changes)
      
      # Fase 4: Registrar resultados
      @sync_session.update!(
        status: 'completed',
        completed_at: Time.current,
        local_changes_count: local_changes.count,
        remote_changes_count: remote_changes.count,
        conflicts_count: conflicts.count,
        sync_results: sync_results
      )
      
      Rails.logger.info "✅ Sync completed successfully"
      sync_results
      
    rescue StandardError => e
      Rails.logger.error "❌ Sync failed: #{e.message}"
      @sync_session.update!(
        status: 'failed',
        error_message: e.message,
        completed_at: Time.current
      )
      raise
    end
  end
  
  private
  
  # Detectar cambios locales desde la última sincronización
  def detect_local_changes
    last_sync = @sync_session.todo_list.sync_sessions.completed.last&.completed_at || 1.day.ago
    
    changes = []
    
    # TodoItems modificados localmente
    @todo_list.todo_items.where('updated_at > ?', last_sync).find_each do |item|
      changes << {
        type: 'todo_item',
        action: item.created_at > last_sync ? 'create' : 'update',
        local_id: item.id,
        external_id: item.external_id,
        data: item.as_json,
        timestamp: item.updated_at,
        checksum: generate_checksum(item.as_json)
      }
    end
    
    # TodoList modificada
    if @todo_list.updated_at > last_sync
      changes << {
        type: 'todo_list',
        action: 'update',
        local_id: @todo_list.id,
        external_id: @todo_list.external_id,
        data: @todo_list.as_json,
        timestamp: @todo_list.updated_at,
        checksum: generate_checksum(@todo_list.as_json)
      }
    end
    
    Rails.logger.info "📊 Detected #{changes.count} local changes"
    changes
  end
  
  # Obtener cambios desde la API externa
  def fetch_remote_changes
    Rails.logger.info "🌐 Fetching remote changes from external API"
    
    begin
      remote_data = @external_api_client.fetch_todo_list(@todo_list.external_id)
      
      changes = []
      
      # Comparar TodoList
      if remote_data['updated_at'] > @todo_list.synced_at
        changes << {
          type: 'todo_list',
          action: 'update',
          external_id: remote_data['id'],
          local_id: @todo_list.id,
          data: remote_data,
          timestamp: Time.parse(remote_data['updated_at']),
          checksum: generate_checksum(remote_data)
        }
      end
      
      # Comparar TodoItems
      remote_data['todo_items']&.each do |remote_item|
        local_item = @todo_list.todo_items.find_by(external_id: remote_item['id'])
        
        if local_item.nil?
          # Item nuevo en remoto
          changes << {
            type: 'todo_item',
            action: 'create',
            external_id: remote_item['id'],
            local_id: nil,
            data: remote_item,
            timestamp: Time.parse(remote_item['updated_at']),
            checksum: generate_checksum(remote_item)
          }
        elsif Time.parse(remote_item['updated_at']) > local_item.synced_at
          # Item modificado en remoto
          changes << {
            type: 'todo_item',
            action: 'update',
            external_id: remote_item['id'],
            local_id: local_item.id,
            data: remote_item,
            timestamp: Time.parse(remote_item['updated_at']),
            checksum: generate_checksum(remote_item)
          }
        end
      end
      
      Rails.logger.info "📊 Fetched #{changes.count} remote changes"
      changes
      
    rescue ExternalApiClient::ApiError => e
      Rails.logger.error "🌐 External API error: #{e.message}"
      []
    end
  end
  
  # Detectar conflictos entre cambios locales y remotos
  def detect_conflicts(local_changes, remote_changes)
    conflicts = []
    
    local_changes.each do |local_change|
      remote_change = remote_changes.find do |rc|
        rc[:type] == local_change[:type] && 
        (rc[:local_id] == local_change[:local_id] || rc[:external_id] == local_change[:external_id])
      end
      
      if remote_change && conflict_exists?(local_change, remote_change)
        conflicts << {
          type: 'data_conflict',
          local_change: local_change,
          remote_change: remote_change,
          conflict_fields: identify_conflict_fields(local_change, remote_change)
        }
        
        Rails.logger.warn "⚠️ Conflict detected for #{local_change[:type]} #{local_change[:local_id]}"
      end
    end
    
    Rails.logger.info "⚠️ Detected #{conflicts.count} conflicts"
    conflicts
  end
  
  # Resolver conflictos según la estrategia configurada
  def resolve_conflicts(conflicts)
    resolved = []
    
    conflicts.each do |conflict|
      case @conflict_resolution_strategy
      when 'last_write_wins'
        resolved << resolve_last_write_wins(conflict)
      when 'merge_changes'
        resolved << resolve_merge_changes(conflict)
      when 'external_priority'
        resolved << conflict[:remote_change]
      when 'local_priority'
        resolved << conflict[:local_change]
      when 'manual_resolution'
        resolved << create_manual_resolution_task(conflict)
      end
    end
    
    Rails.logger.info "✅ Resolved #{resolved.count} conflicts using #{@conflict_resolution_strategy}"
    resolved
  end
  
  # Aplicar cambios sincronizados
  def apply_sync_changes(local_changes, remote_changes, resolved_changes)
    results = {
      local_applied: 0,
      remote_applied: 0,
      conflicts_resolved: resolved_changes&.count || 0,
      errors: []
    }
    
    # Aplicar cambios remotos localmente
    remote_changes.each do |change|
      next if resolved_changes&.any? { |rc| rc[:external_id] == change[:external_id] }
      
      begin
        apply_remote_change_locally(change)
        results[:remote_applied] += 1
      rescue StandardError => e
        results[:errors] << "Remote change error: #{e.message}"
        Rails.logger.error "❌ Error applying remote change: #{e.message}"
      end
    end
    
    # Enviar cambios locales al remoto
    local_changes.each do |change|
      next if resolved_changes&.any? { |rc| rc[:local_id] == change[:local_id] }
      
      begin
        apply_local_change_remotely(change)
        results[:local_applied] += 1
      rescue StandardError => e
        results[:errors] << "Local change error: #{e.message}"
        Rails.logger.error "❌ Error applying local change: #{e.message}"
      end
    end
    
    # Aplicar cambios resueltos
    resolved_changes&.each do |change|
      begin
        apply_resolved_change(change)
      rescue StandardError => e
        results[:errors] << "Resolved change error: #{e.message}"
        Rails.logger.error "❌ Error applying resolved change: #{e.message}"
      end
    end
    
    Rails.logger.info "📊 Sync results: #{results}"
    results
  end
  
  # Métodos auxiliares
  
  def generate_checksum(data)
    Digest::MD5.hexdigest(data.to_json)
  end
  
  def conflict_exists?(local_change, remote_change)
    local_change[:checksum] != remote_change[:checksum]
  end
  
  def identify_conflict_fields(local_change, remote_change)
    local_data = local_change[:data]
    remote_data = remote_change[:data]
    
    conflicts = []
    local_data.each do |key, value|
      if remote_data[key] != value
        conflicts << {
          field: key,
          local_value: value,
          remote_value: remote_data[key]
        }
      end
    end
    
    conflicts
  end
  
  def resolve_last_write_wins(conflict)
    local_timestamp = conflict[:local_change][:timestamp]
    remote_timestamp = conflict[:remote_change][:timestamp]
    
    if local_timestamp > remote_timestamp
      Rails.logger.info "🏆 Local wins for #{conflict[:local_change][:type]}"
      conflict[:local_change]
    else
      Rails.logger.info "🏆 Remote wins for #{conflict[:remote_change][:type]}"
      conflict[:remote_change]
    end
  end
  
  def resolve_merge_changes(conflict)
    # Implementación básica de merge - se puede expandir
    merged_data = conflict[:local_change][:data].merge(conflict[:remote_change][:data]) do |key, local_val, remote_val|
      # Lógica de merge personalizada por campo
      case key
      when 'description'
        "#{local_val} (merged with: #{remote_val})"
      when 'completed'
        local_val || remote_val # True wins
      else
        remote_val # Default: remote wins
      end
    end
    
    conflict[:local_change].merge(data: merged_data)
  end
  
  def create_manual_resolution_task(conflict)
    ConflictResolutionTask.create!(
      sync_session: @sync_session,
      conflict_type: conflict[:type],
      local_data: conflict[:local_change],
      remote_data: conflict[:remote_change],
      status: 'pending'
    )
    
    # Devolver cambio local por defecto hasta resolución manual
    conflict[:local_change]
  end
  
  def apply_remote_change_locally(change)
    case change[:type]
    when 'todo_item'
      apply_remote_todo_item_change(change)
    when 'todo_list'
      apply_remote_todo_list_change(change)
    end
  end
  
  def apply_local_change_remotely(change)
    case change[:action]
    when 'create'
      @external_api_client.create_resource(change[:type], change[:data])
    when 'update'
      @external_api_client.update_resource(change[:type], change[:external_id], change[:data])
    when 'delete'
      @external_api_client.delete_resource(change[:type], change[:external_id])
    end
  end
  
  def apply_remote_todo_item_change(change)
    case change[:action]
    when 'create'
      @todo_list.todo_items.create!(
        description: change[:data]['description'],
        completed: change[:data]['completed'],
        external_id: change[:external_id],
        synced_at: Time.current
      )
    when 'update'
      item = @todo_list.todo_items.find(change[:local_id])
      item.update!(
        description: change[:data]['description'],
        completed: change[:data]['completed'],
        synced_at: Time.current
      )
    end
  end
  
  def apply_remote_todo_list_change(change)
    @todo_list.update!(
      name: change[:data]['name'],
      synced_at: Time.current
    )
  end
  
  def apply_resolved_change(change)
    # Aplicar cambio resuelto tanto local como remotamente
    apply_remote_change_locally(change)
    apply_local_change_remotely(change)
  end
end
