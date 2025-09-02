# frozen_string_literal: true

# SyncDashboardController - Dashboard para monitoreo de sincronización
class SyncDashboardController < ApplicationController
  before_action :set_dashboard_data
  
  # GET /sync_dashboard
  def index
    @recent_sessions = SyncSession.recent.limit(10).includes(:todo_list)
    @pending_conflicts = ConflictResolutionTask.requiring_attention.limit(5)
    @sync_stats = calculate_sync_stats
    @api_health = check_api_health
  end
  
  # GET /sync_dashboard/sessions
  def sessions
    @sessions = SyncSession.includes(:todo_list)
                          .order(started_at: :desc)
                          .page(params[:page])
                          .per(20)
  end
  
  # GET /sync_dashboard/conflicts
  def conflicts
    @conflicts = ConflictResolutionTask.includes(sync_session: :todo_list)
                                      .order(created_at: :desc)
                                      .page(params[:page])
                                      .per(15)
    
    @pending_count = ConflictResolutionTask.pending_count
  end
  
  # POST /sync_dashboard/trigger_sync/:todo_list_id
  def trigger_sync
    @todo_list = TodoList.find(params[:todo_list_id])
    
    unless @todo_list.sync_enabled?
      redirect_to sync_dashboard_path, alert: "Sincronización no está habilitada para '#{@todo_list.name}'"
      return
    end
    
    strategy = params[:strategy] || 'incremental_sync'
    conflict_resolution = params[:conflict_resolution] || 'last_write_wins'
    
    if @todo_list.trigger_sync!(strategy: strategy, conflict_resolution: conflict_resolution)
      redirect_to sync_dashboard_path, 
                  notice: "Sincronización iniciada para '#{@todo_list.name}' con estrategia #{strategy}"
    else
      redirect_to sync_dashboard_path, 
                  alert: "No se pudo iniciar la sincronización para '#{@todo_list.name}'"
    end
  end
  
  # POST /sync_dashboard/enable_sync/:todo_list_id
  def enable_sync
    @todo_list = TodoList.find(params[:todo_list_id])
    external_id = params[:external_id].presence
    
    @todo_list.enable_sync!(external_id: external_id)
    
    redirect_to sync_dashboard_path, 
                notice: "Sincronización habilitada para '#{@todo_list.name}'"
  end
  
  # POST /sync_dashboard/disable_sync/:todo_list_id
  def disable_sync
    @todo_list = TodoList.find(params[:todo_list_id])
    @todo_list.disable_sync!
    
    redirect_to sync_dashboard_path, 
                notice: "Sincronización deshabilitada para '#{@todo_list.name}'"
  end
  
  # POST /sync_dashboard/resolve_conflict/:conflict_id
  def resolve_conflict
    @conflict = ConflictResolutionTask.find(params[:conflict_id])
    resolution_data = params[:resolution_data]
    
    if resolution_data.present?
      @conflict.manual_resolve!(resolution_data, resolved_by: 'dashboard_user')
      redirect_to sync_dashboard_conflicts_path, 
                  notice: "Conflicto resuelto exitosamente"
    else
      redirect_to sync_dashboard_conflicts_path, 
                  alert: "Datos de resolución requeridos"
    end
  end
  
  # POST /sync_dashboard/auto_resolve_conflicts
  def auto_resolve_conflicts
    resolved_count = 0
    
    ConflictResolutionTask.pending.find_each do |task|
      if task.attempt_auto_resolution
        resolved_count += 1
      end
    end
    
    if resolved_count > 0
      redirect_to sync_dashboard_conflicts_path, 
                  notice: "#{resolved_count} conflictos resueltos automáticamente"
    else
      redirect_to sync_dashboard_conflicts_path, 
                  notice: "No hay conflictos que puedan resolverse automáticamente"
    end
  end
  
  # GET /sync_dashboard/api_health
  def api_health
    @health_status = check_api_health
    @sync_stats_external = fetch_external_sync_stats
    
    respond_to do |format|
      format.html
      format.json { render json: { health: @health_status, external_stats: @sync_stats_external } }
    end
  end
  
  # GET /sync_dashboard/stats
  def stats
    @detailed_stats = {
      sync_sessions: SyncSession.stats_summary,
      conflicts: ConflictResolutionTask.stats_summary,
      todo_lists: calculate_todo_lists_stats,
      performance: calculate_performance_stats
    }
    
    respond_to do |format|
      format.html
      format.json { render json: @detailed_stats }
    end
  end
  
  private
  
  def set_dashboard_data
    @total_todo_lists = TodoList.count
    @sync_enabled_lists = TodoList.sync_enabled.count
    @lists_needing_sync = TodoList.sync_enabled.needs_sync.count
  end
  
  def calculate_sync_stats
    {
      total_sessions: SyncSession.count,
      completed_sessions: SyncSession.completed.count,
      failed_sessions: SyncSession.failed.count,
      running_sessions: SyncSession.running.count,
      success_rate: SyncSession.success_rate_overall,
      average_duration: SyncSession.average_duration,
      pending_conflicts: ConflictResolutionTask.pending_count,
      auto_resolution_rate: ConflictResolutionTask.auto_resolution_rate
    }
  end
  
  def calculate_todo_lists_stats
    {
      total: TodoList.count,
      sync_enabled: TodoList.sync_enabled.count,
      needs_sync: TodoList.sync_enabled.needs_sync.count,
      never_synced: TodoList.sync_enabled.where(synced_at: nil).count,
      recently_synced: TodoList.sync_enabled.where('synced_at > ?', 1.hour.ago).count
    }
  end
  
  def calculate_performance_stats
    recent_sessions = SyncSession.completed.where('completed_at > ?', 24.hours.ago)
    
    {
      sessions_last_24h: recent_sessions.count,
      avg_duration_24h: recent_sessions.average("EXTRACT(EPOCH FROM (completed_at - started_at))") || 0,
      fastest_sync: recent_sessions.minimum("EXTRACT(EPOCH FROM (completed_at - started_at))") || 0,
      slowest_sync: recent_sessions.maximum("EXTRACT(EPOCH FROM (completed_at - started_at))") || 0
    }
  end
  
  def check_api_health
    begin
      client = ExternalApiClient.new
      health_data = client.health_check
      
      {
        status: 'healthy',
        latency: health_data['latency'],
        timestamp: health_data['timestamp'],
        version: health_data['version'],
        error: nil
      }
    rescue => e
      Rails.logger.error "🌐 API health check failed: #{e.message}"
      
      {
        status: 'unhealthy',
        latency: nil,
        timestamp: Time.current.iso8601,
        version: nil,
        error: e.message
      }
    end
  end
  
  def fetch_external_sync_stats
    begin
      client = ExternalApiClient.new
      client.sync_stats
    rescue => e
      Rails.logger.error "🌐 Failed to fetch external sync stats: #{e.message}"
      { error: e.message }
    end
  end
end
