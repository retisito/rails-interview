# frozen_string_literal: true

# SyncSession - Modelo para tracking de sesiones de sincronización
class SyncSession < ApplicationRecord
  belongs_to :todo_list
  has_many :conflict_resolution_tasks, dependent: :destroy
  
  # Estados de sincronización
  STATUSES = %w[initiated running completed failed paused cancelled].freeze
  
  validates :status, inclusion: { in: STATUSES }
  validates :strategy, presence: true
  validates :started_at, presence: true
  
  # Scopes
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :running, -> { where(status: 'running') }
  scope :recent, -> { order(started_at: :desc) }
  
  # Callbacks
  before_validation :set_defaults, on: :create
  after_update :broadcast_status_change, if: :saved_change_to_status?
  
  # Métodos de instancia
  
  def duration
    return nil unless started_at
    end_time = completed_at || Time.current
    end_time - started_at
  end
  
  def duration_in_words
    return "N/A" unless duration
    
    if duration < 60
      "#{duration.round}s"
    elsif duration < 3600
      "#{(duration / 60).round}m #{(duration % 60).round}s"
    else
      "#{(duration / 3600).round}h #{((duration % 3600) / 60).round}m"
    end
  end
  
  def success_rate
    return 0 if local_changes_count.zero? && remote_changes_count.zero?
    
    total_changes = (local_changes_count || 0) + (remote_changes_count || 0)
    errors_count = sync_results.dig('errors')&.count || 0
    
    ((total_changes - errors_count).to_f / total_changes * 100).round(2)
  end
  
  def has_conflicts?
    (conflicts_count || 0) > 0
  end
  
  def has_errors?
    sync_results.dig('errors')&.any? || false
  end
  
  def completed_successfully?
    status == 'completed' && !has_errors?
  end
  
  def summary
    {
      id: id,
      status: status,
      strategy: strategy,
      duration: duration_in_words,
      success_rate: "#{success_rate}%",
      changes: {
        local: local_changes_count || 0,
        remote: remote_changes_count || 0,
        conflicts: conflicts_count || 0
      },
      errors: sync_results.dig('errors')&.count || 0,
      started_at: started_at&.strftime("%Y-%m-%d %H:%M:%S"),
      completed_at: completed_at&.strftime("%Y-%m-%d %H:%M:%S")
    }
  end
  
  # Métodos de clase
  
  def self.average_duration
    completed.where.not(completed_at: nil)
             .average("EXTRACT(EPOCH FROM (completed_at - started_at))")
             &.round(2)
  end
  
  def self.success_rate_overall
    completed_sessions = completed.count
    return 0 if completed_sessions.zero?
    
    successful_sessions = completed.select(&:completed_successfully?).count
    (successful_sessions.to_f / completed_sessions * 100).round(2)
  end
  
  def self.stats_summary
    {
      total_sessions: count,
      completed: completed.count,
      failed: failed.count,
      running: running.count,
      average_duration: average_duration || 0,
      overall_success_rate: "#{success_rate_overall}%",
      last_sync: recent.first&.started_at&.strftime("%Y-%m-%d %H:%M:%S") || "Never"
    }
  end
  
  private
  
  def set_defaults
    self.started_at ||= Time.current
    self.status ||= 'initiated'
    self.local_changes_count ||= 0
    self.remote_changes_count ||= 0
    self.conflicts_count ||= 0
    self.sync_results ||= {}
  end
  
  def broadcast_status_change
    # Broadcast status change via Turbo Streams para real-time updates
    broadcast_replace_to(
      "sync_session_#{todo_list_id}",
      target: "sync_session_#{id}",
      partial: "sync_sessions/sync_session",
      locals: { sync_session: self }
    )
    
    Rails.logger.info "📡 Broadcasted status change for SyncSession #{id}: #{status}"
  end
end
