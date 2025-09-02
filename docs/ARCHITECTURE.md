# 🏗️ Arquitectura del Sistema de Sincronización

## 📋 Tabla de Contenidos
- [Visión General](#visión-general)
- [Diagrama de Arquitectura](#diagrama-de-arquitectura)
- [Componentes del Sistema](#componentes-del-sistema)
- [Flujo de Datos](#flujo-de-datos)
- [Patrones de Diseño](#patrones-de-diseño)
- [Escalabilidad](#escalabilidad)
- [Seguridad](#seguridad)

## 🎯 Visión General

El Sistema de Sincronización Bidireccional implementa una arquitectura híbrida que combina lo mejor de Rails con patrones de microservicios, siguiendo el **Plan de Acción Crunchloop - Opción 4: Rails Híbrido Inteligente**.

### 🎯 Principios Arquitectónicos
- **Separación de responsabilidades** clara entre componentes
- **Procesamiento asíncrono** para operaciones de larga duración
- **Resiliencia** con retry automático y circuit breakers
- **Observabilidad** completa con métricas y logging
- **Escalabilidad horizontal** preparada para crecimiento

## 🏗️ Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              FRONTEND LAYER                                    │
├─────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
│  │   Dashboard UI  │    │   TodoList UI   │    │   Admin Panel   │            │
│  │   (Bootstrap)   │    │   (Hotwire)     │    │   (Custom)      │            │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘            │
│           │                       │                       │                   │
│           └───────────────────────┼───────────────────────┘                   │
│                                   │                                           │
│  ┌─────────────────────────────────┼─────────────────────────────────┐        │
│  │                    TURBO STREAMS / ACTION CABLE                  │        │
│  │              (Real-time Updates & Notifications)                 │        │
│  └─────────────────────────────────┼─────────────────────────────────┘        │
└─────────────────────────────────────┼─────────────────────────────────────────┘
                                      │
┌─────────────────────────────────────┼─────────────────────────────────────────┐
│                              RAILS APPLICATION LAYER                         │
├─────────────────────────────────────┼─────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
│  │ Sync Dashboard  │    │ TodoList        │    │ API Controllers │            │
│  │ Controller      │    │ Controllers     │    │ (REST)          │            │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘            │
│           │                       │                       │                   │
│           └───────────────────────┼───────────────────────┘                   │
│                                   │                                           │
│  ┌─────────────────────────────────┼─────────────────────────────────┐        │
│  │                        SERVICE LAYER                            │        │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │
│  │  │   Sync Engine   │    │ External API    │    │ Conflict        │        │
│  │  │   (Core Logic)  │    │ Client          │    │ Resolution      │        │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘        │
│  └─────────────────────────────────┼─────────────────────────────────┘        │
│                                   │                                           │
│  ┌─────────────────────────────────┼─────────────────────────────────┐        │
│  │                      BACKGROUND PROCESSING                       │        │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │
│  │  │ Bidirectional   │    │ Progressive     │    │ Notification    │        │
│  │  │ Sync Job        │    │ Completion Job  │    │ Jobs            │        │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘        │
│  └─────────────────────────────────┼─────────────────────────────────┘        │
└─────────────────────────────────────┼─────────────────────────────────────────┘
                                      │
┌─────────────────────────────────────┼─────────────────────────────────────────┐
│                              DATA LAYER                                      │
├─────────────────────────────────────┼─────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
│  │   TodoLists     │    │   TodoItems     │    │   Sync Sessions │            │
│  │   (ActiveRecord)│    │   (ActiveRecord)│    │   (ActiveRecord)│            │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘            │
│           │                       │                       │                   │
│           └───────────────────────┼───────────────────────┘                   │
│                                   │                                           │
│  ┌─────────────────────────────────┼─────────────────────────────────┐        │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │
│  │  │ Conflict        │    │ Performance     │    │ Audit Logs      │        │
│  │  │ Resolution      │    │ Metrics         │    │ (Future)        │        │
│  │  │ Tasks           │    │ (Future)        │    │                 │        │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘        │
│  └─────────────────────────────────┼─────────────────────────────────┘        │
└─────────────────────────────────────┼─────────────────────────────────────────┘
                                      │
┌─────────────────────────────────────┼─────────────────────────────────────────┐
│                              INFRASTRUCTURE LAYER                           │
├─────────────────────────────────────┼─────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
│  │     Redis       │    │   Sidekiq       │    │   SQLite/       │            │
│  │   (Cache &      │    │   (Job Queue)   │    │   PostgreSQL    │            │
│  │   Sessions)     │    │                 │    │   (Database)    │            │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘            │
│           │                       │                       │                   │
│           └───────────────────────┼───────────────────────┘                   │
│                                   │                                           │
│  ┌─────────────────────────────────┼─────────────────────────────────┐        │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │
│  │  │   Nginx         │    │   Docker        │    │   Monitoring    │        │
│  │  │   (Reverse      │    │   (Containers)  │    │   (Logs &       │        │
│  │  │   Proxy)        │    │                 │    │    Metrics)     │        │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘        │
│  └─────────────────────────────────┼─────────────────────────────────┘        │
└─────────────────────────────────────┼─────────────────────────────────────────┘
                                      │
┌─────────────────────────────────────┼─────────────────────────────────────────┐
│                              EXTERNAL SYSTEMS                                │
├─────────────────────────────────────┼─────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐            │
│  │   External      │    │   Webhooks      │    │   Third-party   │            │
│  │   API           │    │   (Future)      │    │   Services      │            │
│  │   (TodoList)    │    │                 │    │   (Future)      │            │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🧩 Componentes del Sistema

### 1. **Frontend Layer**

#### **Dashboard UI (Bootstrap 5)**
- **Responsabilidad**: Interfaz de monitoreo y control
- **Tecnologías**: HTML5, CSS3, Bootstrap 5, JavaScript
- **Características**:
  - Métricas en tiempo real
  - Controles de sincronización
  - Gestión de conflictos
  - Visualización de estadísticas

#### **TodoList UI (Hotwire)**
- **Responsabilidad**: Interfaz de usuario principal
- **Tecnologías**: Turbo, Stimulus, ERB templates
- **Características**:
  - CRUD completo sin recargas
  - Barras de progreso individuales
  - Actualizaciones en tiempo real
  - Feedback visual inmediato

#### **Real-time Communication**
- **Turbo Streams**: Actualizaciones de UI en tiempo real
- **Action Cable**: WebSockets para notificaciones
- **Stimulus Controllers**: Lógica de cliente interactiva

### 2. **Rails Application Layer**

#### **Controllers**
```ruby
# Sync Dashboard Controller
class SyncDashboardController < ApplicationController
  # Dashboard principal
  def index
  
  # Control de sincronización
  def trigger_sync
  def enable_sync
  def disable_sync
  
  # Gestión de conflictos
  def resolve_conflict
  def auto_resolve_conflicts
  
  # Monitoreo
  def api_health
  def stats
end
```

#### **Service Layer**
```ruby
# Sync Engine - Motor principal
class SyncEngine
  def perform_bidirectional_sync
  def detect_local_changes
  def fetch_remote_changes
  def detect_conflicts
  def resolve_conflicts
  def apply_sync_changes
end

# External API Client
class ExternalApiClient
  def fetch_todo_list
  def create_resource
  def update_resource
  def delete_resource
  def health_check
end
```

### 3. **Background Processing**

#### **Job Queue (Sidekiq)**
```ruby
# Sincronización bidireccional
class BidirectionalSyncJob < ApplicationJob
  queue_as :sync
  retry_on StandardError, wait: :exponentially_longer, attempts: 5
  
  def perform(todo_list_id, sync_strategy:, conflict_resolution:)
end

# Procesamiento progresivo
class ProgressiveCompletionJob < ApplicationJob
  queue_as :default
  
  def perform(todo_list_id)
end
```

#### **Job Processing Flow**
1. **Enqueue**: Job agregado a cola Redis
2. **Processing**: Sidekiq worker procesa job
3. **Execution**: SyncEngine ejecuta lógica
4. **Broadcasting**: Resultados enviados via Turbo Streams
5. **Cleanup**: Métricas y logs actualizados

### 4. **Data Layer**

#### **ActiveRecord Models**
```ruby
# Modelo principal extendido
class TodoList < ApplicationRecord
  has_many :todo_items, dependent: :destroy
  has_many :sync_sessions, dependent: :destroy
  
  # Campos de sincronización
  # external_id, synced_at, sync_enabled
  
  # Métodos de control
  def enable_sync!(external_id: nil)
  def trigger_sync!(strategy:, conflict_resolution:)
  def sync_status
  def sync_stats
end

# Tracking de sesiones
class SyncSession < ApplicationRecord
  belongs_to :todo_list
  has_many :conflict_resolution_tasks, dependent: :destroy
  
  # Estados: initiated, running, completed, failed, paused, cancelled
  # Métricas: duration, success_rate, summary
end

# Resolución de conflictos
class ConflictResolutionTask < ApplicationRecord
  belongs_to :sync_session
  
  # Tipos: data_conflict, timestamp_conflict, deletion_conflict, creation_conflict
  # Estados: pending, reviewing, resolved, rejected, auto_resolved
end
```

#### **Database Schema**
```sql
-- TodoLists con campos de sync
ALTER TABLE todo_lists ADD COLUMN external_id VARCHAR(255);
ALTER TABLE todo_lists ADD COLUMN synced_at TIMESTAMP;
ALTER TABLE todo_lists ADD COLUMN sync_enabled BOOLEAN DEFAULT FALSE;

-- TodoItems con campos de sync
ALTER TABLE todo_items ADD COLUMN external_id VARCHAR(255);
ALTER TABLE todo_items ADD COLUMN synced_at TIMESTAMP;

-- Sync Sessions
CREATE TABLE sync_sessions (
  id BIGSERIAL PRIMARY KEY,
  todo_list_id BIGINT REFERENCES todo_lists(id),
  status VARCHAR(50) NOT NULL,
  strategy VARCHAR(50) NOT NULL,
  started_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP,
  local_changes_count INTEGER DEFAULT 0,
  remote_changes_count INTEGER DEFAULT 0,
  conflicts_count INTEGER DEFAULT 0,
  sync_results JSONB,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Conflict Resolution Tasks
CREATE TABLE conflict_resolution_tasks (
  id BIGSERIAL PRIMARY KEY,
  sync_session_id BIGINT REFERENCES sync_sessions(id),
  conflict_type VARCHAR(50) NOT NULL,
  status VARCHAR(50) NOT NULL,
  local_data JSONB NOT NULL,
  remote_data JSONB NOT NULL,
  resolution_data JSONB,
  conflict_analysis JSONB,
  resolved_at TIMESTAMP,
  resolved_by VARCHAR(255),
  resolution_strategy VARCHAR(50),
  rejection_reason TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### 5. **Infrastructure Layer**

#### **Redis (Cache & Job Queue)**
```yaml
# config/cable.yml
development:
  adapter: redis
  url: redis://localhost:6379/1

# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] || 'redis://localhost:6379/0' }
end
```

#### **Database (SQLite/PostgreSQL)**
```yaml
# config/database.yml
development:
  adapter: sqlite3
  database: db/development.sqlite3

production:
  adapter: postgresql
  database: rails_interview_production
  username: postgres
  password: <%= ENV['DATABASE_PASSWORD'] %>
  host: db
  port: 5432
```

#### **Docker (Containerization)**
```dockerfile
# Dockerfile
FROM ruby:3.3.0-alpine
# Multi-stage build for production optimization
# Nginx reverse proxy
# PostgreSQL for production
# Redis for caching and jobs
```

## 🔄 Flujo de Datos

### 1. **Sincronización Manual**
```
User → Dashboard → Controller → Service → Job Queue → Background Processing → External API → Database → Real-time Updates → User
```

### 2. **Detección Automática de Cambios**
```
Model Update → Callback → Mark for Sync → Background Job → Sync Engine → External API → Database → Notification
```

### 3. **Resolución de Conflictos**
```
Conflict Detection → Analysis → Auto-resolution (if possible) → Manual Review → Resolution → Apply Changes → Notification
```

### 4. **Monitoreo en Tiempo Real**
```
Background Job → Metrics Collection → Turbo Streams → Dashboard Update → User Notification
```

## 🎨 Patrones de Diseño

### 1. **Service Object Pattern**
```ruby
# SyncEngine encapsula lógica compleja
class SyncEngine
  def perform_bidirectional_sync
    # Lógica de sincronización
  end
end
```

### 2. **Strategy Pattern**
```ruby
# Diferentes estrategias de sincronización
SYNC_STRATEGIES = %w[full_sync incremental_sync batch_sync real_time_sync]

# Diferentes estrategias de resolución de conflictos
CONFLICT_STRATEGIES = %w[last_write_wins merge_changes manual_resolution]
```

### 3. **Observer Pattern**
```ruby
# Callbacks en modelos para detectar cambios
class TodoItem < ApplicationRecord
  after_update :trigger_sync_if_needed, if: :should_trigger_sync?
end
```

### 4. **Command Pattern**
```ruby
# Jobs encapsulan comandos de ejecución
class BidirectionalSyncJob < ApplicationJob
  def perform(todo_list_id, sync_strategy:, conflict_resolution:)
    # Ejecutar comando de sincronización
  end
end
```

### 5. **Repository Pattern**
```ruby
# ExternalApiClient actúa como repositorio para API externa
class ExternalApiClient
  def fetch_todo_list(external_id)
    # Abstrae acceso a datos externos
  end
end
```

## 📈 Escalabilidad

### **Escalabilidad Horizontal**

#### **1. Job Processing**
```ruby
# Múltiples workers de Sidekiq
# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.concurrency = ENV.fetch('SIDEKIQ_CONCURRENCY', 5).to_i
end
```

#### **2. Database Scaling**
```sql
-- Índices para optimización
CREATE INDEX idx_todo_lists_sync_enabled ON todo_lists(sync_enabled);
CREATE INDEX idx_todo_lists_synced_at ON todo_lists(synced_at);
CREATE INDEX idx_sync_sessions_status ON sync_sessions(status);
CREATE INDEX idx_sync_sessions_started_at ON sync_sessions(started_at);
```

#### **3. Caching Strategy**
```ruby
# Redis para cache de sesiones y métricas
class SyncSession
  def self.cached_stats
    Rails.cache.fetch("sync_stats", expires_in: 5.minutes) do
      stats_summary
    end
  end
end
```

### **Escalabilidad Vertical**

#### **1. Performance Optimization**
```ruby
# Batch processing para grandes volúmenes
def process_large_dataset
  TodoList.includes(:todo_items).find_in_batches(batch_size: 100) do |batch|
    batch.each { |list| process_sync(list) }
  end
end
```

#### **2. Memory Management**
```ruby
# Streaming para grandes datasets
def stream_sync_results
  SyncSession.find_each do |session|
    yield session.summary
  end
end
```

## 🔒 Seguridad

### **1. API Security**
```ruby
# Autenticación para API externa
class ExternalApiClient
  def initialize(api_key: nil)
    @api_key = api_key || Rails.application.credentials.external_api_key
    self.class.headers['Authorization'] = "Bearer #{@api_key}"
  end
end
```

### **2. Data Validation**
```ruby
# Validación de datos de entrada
class ConflictResolutionTask < ApplicationRecord
  validates :conflict_type, inclusion: { in: CONFLICT_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :local_data, presence: true
  validates :remote_data, presence: true
end
```

### **3. Error Handling**
```ruby
# Manejo seguro de errores
class BidirectionalSyncJob < ApplicationJob
  retry_on ExternalApiClient::RateLimitError, wait: 30.seconds, attempts: 3
  discard_on ExternalApiClient::AuthenticationError
  
  rescue_from StandardError do |exception|
    Rails.logger.error "Sync job failed: #{exception.message}"
    broadcast_sync_error(exception)
  end
end
```

### **4. Input Sanitization**
```ruby
# Sanitización de datos de resolución
def manual_resolve!(resolution_data, resolved_by: nil)
  sanitized_data = resolution_data.deep_transform_values do |value|
    value.is_a?(String) ? value.strip : value
  end
  
  update!(
    status: 'resolved',
    resolution_data: sanitized_data,
    resolved_by: resolved_by&.strip
  )
end
```

## 🚀 Roadmap de Mejoras

### **Fase 1: Optimizaciones Actuales**
- ✅ Sistema de sincronización bidireccional
- ✅ Dashboard de monitoreo
- ✅ Resolución de conflictos
- ✅ Background job processing

### **Fase 2: Mejoras de Performance**
- 🔄 Caching inteligente con Redis
- 🔄 Batch processing optimizado
- 🔄 Métricas de performance avanzadas
- 🔄 Compresión de datos

### **Fase 3: Escalabilidad**
- 🔄 Sharding de base de datos
- 🔄 Load balancing
- 🔄 Microservicios especializados
- 🔄 Event sourcing

### **Fase 4: Integración Avanzada**
- 🔄 Webhooks bidireccionales
- 🔄 Integración con MCP (Model Context Protocol)
- 🔄 Machine Learning para resolución de conflictos
- 🔄 Análisis predictivo de patrones

---

*Arquitectura del Sistema de Sincronización Bidireccional v1.0*
