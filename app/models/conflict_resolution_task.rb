# frozen_string_literal: true

# ConflictResolutionTask - Modelo para manejo de conflictos de sincronización
class ConflictResolutionTask < ApplicationRecord
  belongs_to :sync_session
  
  # Estados de resolución de conflictos
  STATUSES = %w[pending reviewing resolved rejected auto_resolved].freeze
  
  # Tipos de conflicto
  CONFLICT_TYPES = %w[data_conflict timestamp_conflict deletion_conflict creation_conflict].freeze
  
  validates :status, inclusion: { in: STATUSES }
  validates :conflict_type, inclusion: { in: CONFLICT_TYPES }
  validates :local_data, presence: true
  validates :remote_data, presence: true
  
  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :resolved, -> { where(status: 'resolved') }
  scope :auto_resolved, -> { where(status: 'auto_resolved') }
  scope :requiring_attention, -> { where(status: ['pending', 'reviewing']) }
  
  # Callbacks
  before_validation :set_defaults, on: :create
  after_update :notify_resolution, if: :saved_change_to_status?
  
  # Serialización para datos JSON
  serialize :local_data, JSON
  serialize :remote_data, JSON
  serialize :resolution_data, JSON
  serialize :conflict_analysis, JSON
  
  # Métodos de instancia
  
  def conflict_summary
    return "N/A" unless local_data.is_a?(Hash) && remote_data.is_a?(Hash)
    
    differences = []
    
    local_data.each do |key, local_value|
      remote_value = remote_data[key]
      if local_value != remote_value
        differences << {
          field: key,
          local: local_value,
          remote: remote_value,
          type: determine_conflict_type_for_field(local_value, remote_value)
        }
      end
    end
    
    differences
  end
  
  def auto_resolvable?
    # Determinar si el conflicto puede resolverse automáticamente
    summary = conflict_summary
    return false if summary.empty?
    
    # Simple heuristics for auto-resolution
    summary.all? do |diff|
      case diff[:field]
      when 'completed'
        # Completed = true always wins
        diff[:local] == true || diff[:remote] == true
      when 'updated_at', 'synced_at'
        # Timestamp conflicts can be resolved by taking the latest
        true
      when 'description'
        # Text conflicts might need manual resolution
        false
      else
        # Other fields can use last-write-wins
        true
      end
    end
  end
  
  def attempt_auto_resolution
    return false unless auto_resolvable?
    
    Rails.logger.info "🤖 Attempting auto-resolution for conflict #{id}"
    
    resolved_data = resolve_automatically
    
    if resolved_data
      update!(
        status: 'auto_resolved',
        resolution_data: resolved_data,
        resolved_at: Time.current,
        resolution_strategy: 'automatic'
      )
      
      Rails.logger.info "✅ Auto-resolved conflict #{id}"
      true
    else
      Rails.logger.warn "❌ Failed to auto-resolve conflict #{id}"
      false
    end
  end
  
  def manual_resolve!(resolution_data, resolved_by: nil)
    Rails.logger.info "👤 Manual resolution for conflict #{id} by #{resolved_by || 'system'}"
    
    update!(
      status: 'resolved',
      resolution_data: resolution_data,
      resolved_at: Time.current,
      resolved_by: resolved_by,
      resolution_strategy: 'manual'
    )
    
    Rails.logger.info "✅ Manually resolved conflict #{id}"
  end
  
  def reject!(reason: nil, rejected_by: nil)
    Rails.logger.info "❌ Rejecting conflict #{id}: #{reason}"
    
    update!(
      status: 'rejected',
      rejection_reason: reason,
      resolved_at: Time.current,
      resolved_by: rejected_by,
      resolution_strategy: 'rejected'
    )
  end
  
  def time_since_created
    return "N/A" unless created_at
    
    duration = Time.current - created_at
    
    if duration < 60
      "#{duration.round}s ago"
    elsif duration < 3600
      "#{(duration / 60).round}m ago"
    elsif duration < 86400
      "#{(duration / 3600).round}h ago"
    else
      "#{(duration / 86400).round}d ago"
    end
  end
  
  def priority_score
    # Calculate priority based on various factors
    score = 0
    
    # Age factor (older conflicts get higher priority)
    if created_at.present?
      age_hours = (Time.current - created_at) / 1.hour
      score += age_hours * 0.5
    end
    
    # Conflict type factor
    case conflict_type
    when 'deletion_conflict'
      score += 10 # High priority
    when 'creation_conflict'
      score += 5  # Medium priority
    when 'data_conflict'
      score += 3  # Low-medium priority
    else
      score += 1  # Low priority
    end
    
    # Auto-resolvable conflicts get lower priority
    score -= 5 if auto_resolvable?
    
    [score, 0].max.round(2)
  end
  
  # Métodos de clase
  
  def self.pending_count
    pending.count
  end
  
  def self.auto_resolve_pending!
    pending.find_each do |task|
      task.attempt_auto_resolution if task.auto_resolvable?
    end
  end
  
  def self.priority_queue
    requiring_attention.sort_by(&:priority_score).reverse
  end
  
  def self.stats_summary
    {
      total: count,
      pending: pending.count,
      resolved: resolved.count,
      auto_resolved: auto_resolved.count,
      requiring_attention: requiring_attention.count,
      auto_resolution_rate: auto_resolution_rate
    }
  end
  
  def self.auto_resolution_rate
    total_resolved = resolved.count + auto_resolved.count
    return 0 if total_resolved.zero?
    
    (auto_resolved.count.to_f / total_resolved * 100).round(2)
  end
  
  private
  
  def set_defaults
    self.status ||= 'pending'
    self.conflict_analysis ||= analyze_conflict
  end
  
  def analyze_conflict
    return {} unless local_data.is_a?(Hash) && remote_data.is_a?(Hash)
    
    {
      fields_in_conflict: conflict_summary.map { |diff| diff[:field] },
      severity: calculate_severity,
      auto_resolvable: auto_resolvable?,
      priority_score: priority_score,
      analyzed_at: Time.current.iso8601
    }
  end
  
  def calculate_severity
    summary = conflict_summary
    return 'low' if summary.empty?
    
    critical_fields = ['id', 'external_id', 'todo_list_id']
    important_fields = ['description', 'completed']
    
    if summary.any? { |diff| critical_fields.include?(diff[:field]) }
      'critical'
    elsif summary.any? { |diff| important_fields.include?(diff[:field]) }
      'high'
    elsif summary.count > 3
      'medium'
    else
      'low'
    end
  end
  
  def determine_conflict_type_for_field(local_value, remote_value)
    if local_value.nil? && !remote_value.nil?
      'creation'
    elsif !local_value.nil? && remote_value.nil?
      'deletion'
    elsif local_value.is_a?(String) && remote_value.is_a?(String)
      'text_modification'
    elsif [local_value, remote_value].all? { |v| [true, false].include?(v) }
      'boolean_conflict'
    else
      'value_conflict'
    end
  end
  
  def resolve_automatically
    resolved_data = local_data.dup
    
    conflict_summary.each do |diff|
      field = diff[:field]
      local_value = diff[:local]
      remote_value = diff[:remote]
      
      resolved_value = case field
                      when 'completed'
                        # True wins
                        local_value || remote_value
                      when 'updated_at', 'synced_at'
                        # Latest timestamp wins
                        [local_value, remote_value].compact.max
                      when 'description'
                        # For demo, prefer longer description
                        local_value.to_s.length > remote_value.to_s.length ? local_value : remote_value
                      else
                        # Default: remote wins
                        remote_value
                      end
      
      resolved_data[field] = resolved_value
    end
    
    resolved_data
  end
  
  def notify_resolution
    # Broadcast resolution update via Turbo Streams
    broadcast_replace_to(
      "conflict_resolution_tasks",
      target: "conflict_task_#{id}",
      partial: "conflict_resolution_tasks/conflict_task",
      locals: { task: self }
    )
    
    Rails.logger.info "📡 Broadcasted resolution update for ConflictTask #{id}: #{status}"
  end
end
