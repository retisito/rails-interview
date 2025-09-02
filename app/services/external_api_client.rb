# frozen_string_literal: true

# ExternalApiClient - Cliente para API Externa
# Simula la integración con una API externa de TodoList
class ExternalApiClient
  include HTTParty
  
  # Configuración de la API externa (simulada)
  base_uri Rails.env.production? ? 'https://external-todo-api.com/api/v1' : 'http://localhost:4000/api/v1'
  
  headers({
    'Content-Type' => 'application/json',
    'Accept' => 'application/json',
    'User-Agent' => 'TodoList-Sync-Client/1.0'
  })
  
  # Timeout y retry configuration
  default_timeout 30
  
  class ApiError < StandardError; end
  class AuthenticationError < ApiError; end
  class RateLimitError < ApiError; end
  class ServerError < ApiError; end
  
  def initialize(api_key: nil, base_url: nil)
    @api_key = api_key || Rails.application.credentials.external_api_key || 'demo_api_key_12345'
    @base_url = base_url
    @retry_count = 0
    @max_retries = 3
    
    # Configurar headers de autenticación
    self.class.headers['Authorization'] = "Bearer #{@api_key}"
    self.class.base_uri(@base_url) if @base_url
    
    Rails.logger.info "🌐 ExternalApiClient initialized with base_uri: #{self.class.base_uri}"
  end
  
  # Obtener TodoList completa desde API externa
  def fetch_todo_list(external_id)
    Rails.logger.info "🌐 Fetching TodoList #{external_id} from external API"
    
    # En desarrollo, simular respuesta
    if Rails.env.development? && external_id
      return simulate_external_todo_list(external_id)
    end
    
    response = with_error_handling do
      self.class.get("/todolists/#{external_id}")
    end
    
    Rails.logger.info "✅ Successfully fetched TodoList #{external_id}"
    response.parsed_response
  end
  
  # Crear recurso en API externa
  def create_resource(resource_type, data)
    Rails.logger.info "🌐 Creating #{resource_type} in external API"
    
    endpoint = case resource_type
               when 'todo_list'
                 '/todolists'
               when 'todo_item'
                 "/todolists/#{data['todo_list_id']}/todos"
               else
                 raise ApiError, "Unknown resource type: #{resource_type}"
               end
    
    # En desarrollo, simular respuesta exitosa
    if Rails.env.development?
      return simulate_create_response(resource_type, data)
    end
    
    response = with_error_handling do
      self.class.post(endpoint, body: data.to_json)
    end
    
    Rails.logger.info "✅ Successfully created #{resource_type}"
    response.parsed_response
  end
  
  # Actualizar recurso en API externa
  def update_resource(resource_type, external_id, data)
    Rails.logger.info "🌐 Updating #{resource_type} #{external_id} in external API"
    
    endpoint = case resource_type
               when 'todo_list'
                 "/todolists/#{external_id}"
               when 'todo_item'
                 "/todolists/#{data['todo_list_id']}/todos/#{external_id}"
               else
                 raise ApiError, "Unknown resource type: #{resource_type}"
               end
    
    # En desarrollo, simular respuesta exitosa
    if Rails.env.development?
      return simulate_update_response(resource_type, external_id, data)
    end
    
    response = with_error_handling do
      self.class.put(endpoint, body: data.to_json)
    end
    
    Rails.logger.info "✅ Successfully updated #{resource_type} #{external_id}"
    response.parsed_response
  end
  
  # Eliminar recurso en API externa
  def delete_resource(resource_type, external_id)
    Rails.logger.info "🌐 Deleting #{resource_type} #{external_id} from external API"
    
    endpoint = case resource_type
               when 'todo_list'
                 "/todolists/#{external_id}"
               when 'todo_item'
                 "/todos/#{external_id}"
               else
                 raise ApiError, "Unknown resource type: #{resource_type}"
               end
    
    # En desarrollo, simular respuesta exitosa
    if Rails.env.development?
      return simulate_delete_response(resource_type, external_id)
    end
    
    response = with_error_handling do
      self.class.delete(endpoint)
    end
    
    Rails.logger.info "✅ Successfully deleted #{resource_type} #{external_id}"
    response.parsed_response
  end
  
  # Verificar conectividad con API externa
  def health_check
    Rails.logger.info "🌐 Performing health check on external API"
    
    # En desarrollo, simular respuesta exitosa
    if Rails.env.development?
      return {
        status: 'healthy',
        timestamp: Time.current.iso8601,
        version: '1.0.0',
        latency: rand(50..200)
      }
    end
    
    start_time = Time.current
    response = with_error_handling do
      self.class.get('/health')
    end
    latency = ((Time.current - start_time) * 1000).round
    
    result = response.parsed_response.merge('latency' => latency)
    Rails.logger.info "✅ External API health check passed (#{latency}ms)"
    result
  end
  
  # Obtener estadísticas de sincronización
  def sync_stats
    Rails.logger.info "🌐 Fetching sync stats from external API"
    
    # En desarrollo, simular estadísticas
    if Rails.env.development?
      return {
        total_syncs: rand(100..1000),
        successful_syncs: rand(90..950),
        failed_syncs: rand(1..50),
        last_sync_at: rand(1..24).hours.ago.iso8601,
        avg_sync_duration: rand(1000..5000),
        rate_limit_remaining: rand(500..1000)
      }
    end
    
    response = with_error_handling do
      self.class.get('/sync/stats')
    end
    
    Rails.logger.info "✅ Successfully fetched sync stats"
    response.parsed_response
  end
  
  private
  
  # Manejo de errores con retry automático
  def with_error_handling
    begin
      response = yield
      
      case response.code
      when 200..299
        response
      when 401
        raise AuthenticationError, "Invalid API key or authentication failed"
      when 429
        raise RateLimitError, "Rate limit exceeded. Retry after: #{response.headers['retry-after']}"
      when 500..599
        raise ServerError, "Server error: #{response.code} - #{response.message}"
      else
        raise ApiError, "Unexpected response: #{response.code} - #{response.message}"
      end
      
    rescue Net::TimeoutError, Net::OpenTimeout => e
      Rails.logger.error "🌐 Timeout error: #{e.message}"
      retry_request { yield }
    rescue SocketError, Errno::ECONNREFUSED => e
      Rails.logger.error "🌐 Connection error: #{e.message}"
      retry_request { yield }
    rescue RateLimitError => e
      Rails.logger.warn "🌐 Rate limit hit: #{e.message}"
      sleep(2 ** @retry_count) # Exponential backoff
      retry_request { yield }
    rescue ServerError => e
      Rails.logger.error "🌐 Server error: #{e.message}"
      retry_request { yield }
    end
  end
  
  def retry_request
    if @retry_count < @max_retries
      @retry_count += 1
      Rails.logger.info "🔄 Retrying request (#{@retry_count}/#{@max_retries})"
      sleep(1 * @retry_count) # Linear backoff
      yield
    else
      Rails.logger.error "❌ Max retries exceeded"
      raise ApiError, "Max retries (#{@max_retries}) exceeded"
    end
  ensure
    @retry_count = 0
  end
  
  # Métodos de simulación para desarrollo
  
  def simulate_external_todo_list(external_id)
    {
      'id' => external_id,
      'name' => "External TodoList #{external_id}",
      'created_at' => 2.days.ago.iso8601,
      'updated_at' => rand(1..12).hours.ago.iso8601,
      'synced_at' => rand(1..6).hours.ago.iso8601,
      'todo_items' => simulate_external_todo_items(external_id)
    }
  end
  
  def simulate_external_todo_items(todo_list_external_id)
    (1..rand(3..8)).map do |i|
      {
        'id' => "ext_item_#{todo_list_external_id}_#{i}",
        'todo_list_id' => todo_list_external_id,
        'description' => "External Task #{i} for List #{todo_list_external_id}",
        'completed' => [true, false].sample,
        'created_at' => rand(1..48).hours.ago.iso8601,
        'updated_at' => rand(1..12).hours.ago.iso8601,
        'synced_at' => rand(1..6).hours.ago.iso8601
      }
    end
  end
  
  def simulate_create_response(resource_type, data)
    {
      'id' => "ext_#{resource_type}_#{SecureRandom.hex(4)}",
      'created_at' => Time.current.iso8601,
      'updated_at' => Time.current.iso8601
    }.merge(data.except('id'))
  end
  
  def simulate_update_response(resource_type, external_id, data)
    {
      'id' => external_id,
      'updated_at' => Time.current.iso8601
    }.merge(data)
  end
  
  def simulate_delete_response(resource_type, external_id)
    {
      'id' => external_id,
      'deleted' => true,
      'deleted_at' => Time.current.iso8601
    }
  end
end
