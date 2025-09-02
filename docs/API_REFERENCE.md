# 📚 API Reference - Sistema de Sincronización

## 📋 Tabla de Contenidos
- [Endpoints del Dashboard](#endpoints-del-dashboard)
- [API de Sincronización](#api-de-sincronización)
- [Modelos y Estructuras](#modelos-y-estructuras)
- [Códigos de Error](#códigos-de-error)
- [Ejemplos de Uso](#ejemplos-de-uso)

## 🎛️ Endpoints del Dashboard

### **GET** `/sync_dashboard`
Dashboard principal de sincronización.

**Respuesta:**
```html
<!-- Vista HTML con métricas en tiempo real -->
<div class="sync-dashboard">
  <!-- Métricas principales -->
  <!-- Lista de TodoLists con controles -->
  <!-- Sesiones recientes -->
  <!-- Conflictos pendientes -->
</div>
```

### **GET** `/sync_dashboard/api_health`
Estado de salud de la API externa.

**Respuesta JSON:**
```json
{
  "status": "healthy",
  "latency": 150,
  "timestamp": "2025-09-02T14:30:00Z",
  "version": "1.0.0",
  "error": null
}
```

### **GET** `/sync_dashboard/stats`
Estadísticas detalladas del sistema.

**Respuesta JSON:**
```json
{
  "sync_sessions": {
    "total": 25,
    "completed": 20,
    "failed": 3,
    "running": 2,
    "average_duration": 12.5,
    "overall_success_rate": "85.0%",
    "last_sync": "2025-09-02 14:25:00"
  },
  "conflicts": {
    "total": 8,
    "pending": 2,
    "resolved": 5,
    "auto_resolved": 1,
    "requiring_attention": 2,
    "auto_resolution_rate": "83.3"
  },
  "todo_lists": {
    "total": 15,
    "sync_enabled": 8,
    "needs_sync": 3,
    "never_synced": 2,
    "recently_synced": 5
  },
  "performance": {
    "sessions_last_24h": 12,
    "avg_duration_24h": 8.3,
    "fastest_sync": 2.1,
    "slowest_sync": 45.2
  }
}
```

### **GET** `/sync_dashboard/sessions`
Lista de sesiones de sincronización.

**Parámetros:**
- `page` (opcional): Número de página para paginación

**Respuesta:**
```html
<!-- Vista HTML con tabla de sesiones -->
<table class="sessions-table">
  <thead>
    <tr>
      <th>TodoList</th>
      <th>Estado</th>
      <th>Estrategia</th>
      <th>Duración</th>
      <th>Cambios</th>
      <th>Fecha</th>
    </tr>
  </thead>
  <tbody>
    <!-- Filas de sesiones -->
  </tbody>
</table>
```

### **GET** `/sync_dashboard/conflicts`
Lista de conflictos de sincronización.

**Parámetros:**
- `page` (opcional): Número de página para paginación

**Respuesta:**
```html
<!-- Vista HTML con tabla de conflictos -->
<table class="conflicts-table">
  <thead>
    <tr>
      <th>Tipo</th>
      <th>TodoList</th>
      <th>Estado</th>
      <th>Prioridad</th>
      <th>Fecha</th>
      <th>Acciones</th>
    </tr>
  </thead>
  <tbody>
    <!-- Filas de conflictos -->
  </tbody>
</table>
```

## 🔄 API de Sincronización

### **POST** `/sync_dashboard/trigger_sync/:todo_list_id`
Inicia sincronización manual para una TodoList.

**Parámetros:**
- `strategy` (opcional): Estrategia de sincronización (`incremental_sync`, `full_sync`, `batch_sync`, `real_time_sync`)
- `conflict_resolution` (opcional): Estrategia de resolución (`last_write_wins`, `merge_changes`, `external_priority`, `local_priority`, `manual_resolution`)

**Ejemplo:**
```bash
curl -X POST "http://localhost:3000/sync_dashboard/trigger_sync/1" \
  -H "Content-Type: application/json" \
  -d '{
    "strategy": "incremental_sync",
    "conflict_resolution": "last_write_wins"
  }'
```

**Respuesta:**
```json
{
  "status": "success",
  "message": "Sincronización iniciada para 'Mi Lista' con estrategia incremental_sync",
  "job_id": "sync_job_12345",
  "estimated_duration": "30-60 seconds"
}
```

### **POST** `/sync_dashboard/enable_sync/:todo_list_id`
Habilita sincronización para una TodoList.

**Parámetros:**
- `external_id` (opcional): ID externo para la lista

**Ejemplo:**
```bash
curl -X POST "http://localhost:3000/sync_dashboard/enable_sync/1" \
  -H "Content-Type: application/json" \
  -d '{
    "external_id": "ext_list_123"
  }'
```

**Respuesta:**
```json
{
  "status": "success",
  "message": "Sincronización habilitada para 'Mi Lista'",
  "external_id": "ext_list_123",
  "sync_enabled": true
}
```

### **POST** `/sync_dashboard/disable_sync/:todo_list_id`
Deshabilita sincronización para una TodoList.

**Ejemplo:**
```bash
curl -X POST "http://localhost:3000/sync_dashboard/disable_sync/1"
```

**Respuesta:**
```json
{
  "status": "success",
  "message": "Sincronización deshabilitada para 'Mi Lista'",
  "sync_enabled": false
}
```

### **POST** `/sync_dashboard/resolve_conflict/:conflict_id`
Resuelve un conflicto manualmente.

**Parámetros:**
- `resolution_data`: Datos de resolución del conflicto

**Ejemplo:**
```bash
curl -X POST "http://localhost:3000/sync_dashboard/resolve_conflict/1" \
  -H "Content-Type: application/json" \
  -d '{
    "resolution_data": {
      "description": "Descripción resuelta",
      "completed": true
    }
  }'
```

**Respuesta:**
```json
{
  "status": "success",
  "message": "Conflicto resuelto exitosamente",
  "conflict_id": 1,
  "resolution_strategy": "manual"
}
```

### **POST** `/sync_dashboard/auto_resolve_conflicts`
Intenta resolver conflictos automáticamente.

**Ejemplo:**
```bash
curl -X POST "http://localhost:3000/sync_dashboard/auto_resolve_conflicts"
```

**Respuesta:**
```json
{
  "status": "success",
  "message": "3 conflictos resueltos automáticamente",
  "resolved_count": 3,
  "remaining_conflicts": 1
}
```

## 🗄️ Modelos y Estructuras

### SyncSession

**Estructura:**
```ruby
{
  id: 1,
  todo_list_id: 1,
  status: "completed", # initiated, running, completed, failed, paused, cancelled
  strategy: "incremental_sync",
  started_at: "2025-09-02T14:00:00Z",
  completed_at: "2025-09-02T14:02:30Z",
  local_changes_count: 3,
  remote_changes_count: 2,
  conflicts_count: 1,
  sync_results: {
    local_applied: 3,
    remote_applied: 2,
    conflicts_resolved: 1,
    errors: []
  },
  error_message: null,
  created_at: "2025-09-02T14:00:00Z",
  updated_at: "2025-09-02T14:02:30Z"
}
```

**Métodos:**
```ruby
# Duración de la sesión
session.duration # => 150.5 (segundos)
session.duration_in_words # => "2m 30s"

# Tasa de éxito
session.success_rate # => 85.5

# Resumen
session.summary # => Hash con estadísticas
```

### ConflictResolutionTask

**Estructura:**
```ruby
{
  id: 1,
  sync_session_id: 1,
  conflict_type: "data_conflict", # data_conflict, timestamp_conflict, deletion_conflict, creation_conflict
  status: "pending", # pending, reviewing, resolved, rejected, auto_resolved
  local_data: {
    "id": 1,
    "description": "Tarea local",
    "completed": false,
    "updated_at": "2025-09-02T14:00:00Z"
  },
  remote_data: {
    "id": "ext_1",
    "description": "Tarea remota",
    "completed": true,
    "updated_at": "2025-09-02T13:30:00Z"
  },
  resolution_data: null,
  conflict_analysis: {
    "fields_in_conflict": ["description", "completed"],
    "severity": "high",
    "auto_resolvable": false,
    "priority_score": 8.5,
    "analyzed_at": "2025-09-02T14:00:00Z"
  },
  resolved_at: null,
  resolved_by: null,
  resolution_strategy: null,
  rejection_reason: null,
  created_at: "2025-09-02T14:00:00Z",
  updated_at: "2025-09-02T14:00:00Z"
}
```

**Métodos:**
```ruby
# Resumen del conflicto
conflict.conflict_summary # => Array de diferencias

# Auto-resolución
conflict.auto_resolvable? # => true/false
conflict.attempt_auto_resolution # => true/false

# Resolución manual
conflict.manual_resolve!(data, resolved_by: "admin")

# Tiempo desde creación
conflict.time_since_created # => "2h ago"

# Puntuación de prioridad
conflict.priority_score # => 8.5
```

### TodoList (Extended)

**Campos adicionales:**
```ruby
{
  # Campos existentes...
  external_id: "ext_list_123",
  synced_at: "2025-09-02T14:00:00Z",
  sync_enabled: true
}
```

**Métodos de sincronización:**
```ruby
# Control de sync
list.enable_sync!(external_id: "ext_123")
list.disable_sync!
list.trigger_sync!(strategy: 'incremental_sync')

# Estado
list.sync_enabled? # => true
list.needs_sync? # => true
list.sync_status # => "needs_sync"
list.sync_status_color # => "warning"
list.sync_status_icon # => "exclamation-triangle-fill"

# Estadísticas
list.sync_stats # => Hash con estadísticas
list.last_sync_session # => SyncSession object
```

### TodoItem (Extended)

**Campos adicionales:**
```ruby
{
  # Campos existentes...
  external_id: "ext_item_456",
  synced_at: "2025-09-02T14:00:00Z"
}
```

**Métodos de sincronización:**
```ruby
# Estado
item.needs_sync? # => true
item.sync_status # => "needs_sync"
item.sync_status_badge # => { text: "Pendiente Sync", color: "warning", icon: "clock" }

# Control
item.mark_synced!
item.external_reference # => "ext_item_456" o "local_123"
```

## ❌ Códigos de Error

### Errores HTTP

| Código | Descripción | Solución |
|--------|-------------|----------|
| `400` | Bad Request | Verificar parámetros de la petición |
| `404` | Not Found | Verificar que el recurso existe |
| `422` | Unprocessable Entity | Verificar datos de entrada |
| `500` | Internal Server Error | Revisar logs del servidor |

### Errores de Sincronización

| Error | Descripción | Solución |
|-------|-------------|----------|
| `ExternalApiClient::AuthenticationError` | API key inválida | Verificar configuración de API |
| `ExternalApiClient::RateLimitError` | Límite de requests excedido | Esperar y reintentar |
| `ExternalApiClient::ServerError` | Error del servidor externo | Revisar estado de API externa |
| `ExternalApiClient::ApiError` | Error general de API | Revisar conectividad y configuración |

### Errores de Conflictos

| Error | Descripción | Solución |
|-------|-------------|----------|
| `ConflictResolutionError` | Error en resolución de conflictos | Revisar datos de conflicto |
| `AutoResolutionFailed` | Auto-resolución falló | Resolver manualmente |
| `InvalidResolutionData` | Datos de resolución inválidos | Verificar formato de datos |

## 💡 Ejemplos de Uso

### Ejemplo 1: Habilitar Sync y Sincronizar

```ruby
# 1. Habilitar sincronización
list = TodoList.find(1)
list.enable_sync!(external_id: "ext_list_123")

# 2. Verificar estado
puts list.sync_status # => "never_synced"

# 3. Trigger sincronización
list.trigger_sync!(strategy: 'incremental_sync')

# 4. Monitorear progreso
session = list.last_sync_session
puts session.status # => "running"

# 5. Verificar resultado
session.reload
puts session.status # => "completed"
puts session.success_rate # => 100.0
```

### Ejemplo 2: Manejar Conflictos

```ruby
# 1. Ver conflictos pendientes
conflicts = ConflictResolutionTask.pending
puts "Conflictos pendientes: #{conflicts.count}"

# 2. Intentar auto-resolución
conflicts.each do |conflict|
  if conflict.auto_resolvable?
    conflict.attempt_auto_resolution
    puts "Conflicto #{conflict.id} auto-resuelto"
  end
end

# 3. Resolver manualmente
remaining_conflicts = ConflictResolutionTask.pending
remaining_conflicts.each do |conflict|
  resolution_data = {
    description: "Descripción resuelta manualmente",
    completed: true
  }
  conflict.manual_resolve!(resolution_data, resolved_by: "admin")
  puts "Conflicto #{conflict.id} resuelto manualmente"
end
```

### Ejemplo 3: Monitoreo y Métricas

```ruby
# 1. Estadísticas generales
stats = SyncSession.stats_summary
puts "Sesiones totales: #{stats[:total_sessions]}"
puts "Tasa de éxito: #{stats[:overall_success_rate]}"

# 2. Performance
performance = SyncSession.average_duration
puts "Duración promedio: #{performance}s"

# 3. Conflictos
conflict_stats = ConflictResolutionTask.stats_summary
puts "Auto-resolución: #{conflict_stats[:auto_resolution_rate]}%"

# 4. Health check
client = ExternalApiClient.new
health = client.health_check
puts "API externa: #{health['status']} (#{health['latency']}ms)"
```

### Ejemplo 4: API REST

```bash
# 1. Verificar estado del sistema
curl -X GET "http://localhost:3000/sync_dashboard/api_health"

# 2. Obtener estadísticas
curl -X GET "http://localhost:3000/sync_dashboard/stats"

# 3. Habilitar sync
curl -X POST "http://localhost:3000/sync_dashboard/enable_sync/1" \
  -H "Content-Type: application/json" \
  -d '{"external_id": "ext_list_123"}'

# 4. Trigger sincronización
curl -X POST "http://localhost:3000/sync_dashboard/trigger_sync/1" \
  -H "Content-Type: application/json" \
  -d '{
    "strategy": "incremental_sync",
    "conflict_resolution": "last_write_wins"
  }'

# 5. Auto-resolver conflictos
curl -X POST "http://localhost:3000/sync_dashboard/auto_resolve_conflicts"
```

### Ejemplo 5: Webhooks (Futuro)

```ruby
# Configurar webhook para notificaciones
class SyncWebhookController < ApplicationController
  def sync_completed
    # Procesar notificación de sync completada
    session_id = params[:session_id]
    session = SyncSession.find(session_id)
    
    # Enviar notificación a usuarios
    NotificationService.notify_sync_completed(session)
  end
  
  def conflict_detected
    # Procesar notificación de conflicto
    conflict_id = params[:conflict_id]
    conflict = ConflictResolutionTask.find(conflict_id)
    
    # Notificar a administradores
    AdminNotificationService.notify_conflict(conflict)
  end
end
```

---

## 📞 Soporte

Para soporte técnico:

1. **Revisar logs**: `tail -f log/development.log | grep "🔄"`
2. **Dashboard**: http://localhost:3000/sync_dashboard
3. **Sidekiq**: http://localhost:3000/sidekiq
4. **Documentación**: `docs/SYNC_SYSTEM.md`

---

*API Reference - Sistema de Sincronización Bidireccional v1.0*
