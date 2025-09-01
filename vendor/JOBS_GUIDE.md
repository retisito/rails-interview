# 🚀 Jobs en Background - TodoList App

Esta aplicación incluye un sistema completo de jobs en background usando **Active Job** con **Sidekiq** como backend.

## 📋 Descripción General

El sistema simula un proceso automático que completa tareas pendientes con diferentes estrategias de delay para demostrar:
- ⏱️ **Procesamiento asíncrono** con Active Jobs
- 🔄 **Colas de trabajo** con Sidekiq
- 📊 **Monitoreo** de jobs en tiempo real
- 🎯 **Diferentes estrategias** de procesamiento

## 🎯 Funcionalidades Implementadas

### **1. AutoCompleteTodoItemsJob**
Job principal que completa todas las tareas pendientes de una lista.

```ruby
# Completar lista con delay de 5 segundos
AutoCompleteTodoItemsJob.perform_later(todo_list.id, 5)
```

**Características:**
- ✅ Simula delay configurable
- ✅ Completa tareas secuencialmente 
- ✅ Logging detallado del progreso
- ✅ Manejo de errores robusto

### **2. AutoCompleteBatchJob**
Job para completar tareas en lotes específicos.

```ruby
# Completar lote de items específicos
AutoCompleteBatchJob.perform_later(todo_list.id, [1,2,3], 10)
```

**Características:**
- 📦 Procesamiento por lotes
- ⏰ Delay entre lotes configurable
- 🎯 Control granular de items

### **3. AutoCompletionService**
Servicio que gestiona la programación de jobs.

#### **Métodos Disponibles:**

```ruby
# Completado simple
AutoCompletionService.schedule_completion(todo_list, 5)

# Completado con delay aleatorio
AutoCompletionService.schedule_completion_with_random_delay(todo_list, 5, 30)

# Completado por lotes
AutoCompletionService.schedule_batch_completion(todo_list, 3, 10)

# Estadísticas de Sidekiq
AutoCompletionService.get_job_stats
```

## 🌐 API Endpoints

### **POST /api/todolists/:id/auto_complete**
Programa completado automático de una lista.

#### **Parámetros:**

```json
{
  "mode": "simple|random|batch",
  "delay_seconds": 5,
  "min_delay": 5,
  "max_delay": 30,
  "batch_size": 3,
  "delay_between_batches": 10
}
```

#### **Ejemplo de Respuesta:**

```json
{
  "message": "Auto-completion scheduled successfully",
  "todo_list": {
    "id": 1,
    "name": "My List",
    "pending_items_count": 5
  },
  "job_details": {
    "job_id": "abc123",
    "todo_list_id": 1,
    "delay_seconds": 5,
    "scheduled_at": "2024-01-01T10:00:00Z",
    "estimated_completion_at": "2024-01-01T10:00:05Z"
  }
}
```

### **GET /api/jobs/stats**
Obtiene estadísticas de Sidekiq.

### **GET /api/jobs/queues**
Lista el estado de las colas de trabajo.

## 🖥️ Interfaz Web

### **Botones de Completado Automático**
En la vista de cada TodoList (`/todolists/:id`):

- 🚀 **Completar Rápido (5s)** - Completado simple con 5s de delay
- ⏰ **Completar Lento (15s)** - Completado simple con 15s de delay  
- 🎲 **Completar Aleatorio** - Delay aleatorio entre 5-30s
- 📦 **Completar por Lotes** - Procesa en lotes de 3 items

### **Monitor de Jobs**
- 📊 **Sidekiq Web UI**: `http://localhost:3000/sidekiq`
- 🔄 **Auto-refresh** de la página después del completado
- 🔔 **Notificaciones toast** para feedback

## 🐳 Docker Setup

### **Servicios Incluidos:**
- **web**: Aplicación Rails principal
- **sidekiq**: Worker para jobs en background  
- **redis**: Backend para colas de Sidekiq
- **postgres**: Base de datos principal

### **Comandos:**

```bash
# Deploy completo con jobs
./deploy.sh production

# Solo desarrollo con jobs
docker-compose -f docker-compose.dev.yml up -d
```

## 🧪 Testing y Demo

### **1. Demo Script**
```bash
# Ejecutar demo interactivo
rails runner demo_jobs.rb
```

### **2. Tests Manuales con cURL**

```bash
# Completado simple
curl -X POST "http://localhost:3000/api/todolists/1/auto_complete" \
  -H "Content-Type: application/json" \
  -d '{"mode": "simple", "delay_seconds": 5}'

# Completado aleatorio  
curl -X POST "http://localhost:3000/api/todolists/1/auto_complete" \
  -H "Content-Type: application/json" \
  -d '{"mode": "random", "min_delay": 5, "max_delay": 30}'

# Completado por lotes
curl -X POST "http://localhost:3000/api/todolists/1/auto_complete" \
  -H "Content-Type: application/json" \
  -d '{"mode": "batch", "batch_size": 3, "delay_between_batches": 10}'

# Ver estadísticas
curl http://localhost:3000/api/jobs/stats
```

### **3. Postman Collection**
Los endpoints están incluidos en `todo_list_api.postman_collection.json`.

## 📊 Monitoreo

### **Sidekiq Web UI**
- **URL**: `http://localhost:3000/sidekiq`
- **Funciones**:
  - ✅ Ver jobs en cola, procesando, completados
  - ❌ Ver jobs fallidos y reintentar
  - 📊 Estadísticas en tiempo real
  - 🔄 Control de workers

### **Logs de Aplicación**
```bash
# Ver logs de jobs
docker-compose logs -f web
docker-compose logs -f sidekiq

# En desarrollo
tail -f log/development.log
```

### **Métricas Disponibles**
- **processed**: Jobs completados exitosamente
- **failed**: Jobs fallidos
- **busy**: Workers actualmente procesando
- **enqueued**: Jobs en cola esperando
- **scheduled**: Jobs programados para el futuro
- **retries**: Jobs en cola de reintentos

## 🔧 Configuración Avanzada

### **Configurar Colas Personalizadas**
```ruby
# app/jobs/my_job.rb
class MyJob < ApplicationJob
  queue_as :critical  # o :default, :low_priority, etc.
end
```

### **Configurar Reintentos**
```ruby
class AutoCompleteTodoItemsJob < ApplicationJob
  retry_on StandardError, wait: 5.seconds, attempts: 3
  discard_on ActiveRecord::RecordNotFound
end
```

### **Configurar Workers por Cola**
```yaml
# config/sidekiq.yml
:queues:
  - critical
  - default
  - low_priority
```

## 🚨 Troubleshooting

### **Problemas Comunes**

1. **Jobs no se ejecutan**
   - ✅ Verificar que Redis esté corriendo
   - ✅ Verificar que Sidekiq esté activo
   - ✅ Revisar logs de Sidekiq

2. **Jobs fallidos**
   - 🔍 Revisar en Sidekiq Web UI
   - 📝 Verificar logs de errores
   - 🔄 Usar "Retry" en la interfaz

3. **Performance lento**
   - ⚡ Aumentar número de workers
   - 📊 Revisar métricas de Redis
   - 🔄 Optimizar queries en jobs

### **Comandos de Diagnóstico**

```bash
# Estado de Redis
redis-cli ping

# Procesos de Sidekiq
ps aux | grep sidekiq

# Memoria de Redis
redis-cli info memory

# Test de conectividad
rails runner "puts Sidekiq.redis(&:ping)"
```

## 🔮 Extensiones Futuras

### **Posibles Mejoras:**
- 📧 **Notificaciones por email** al completar
- 📱 **WebSockets** para updates en tiempo real
- 📊 **Dashboard personalizado** de métricas
- 🔔 **Sistema de alertas** para jobs fallidos
- ⏰ **Jobs programados** con cron
- 🎯 **Completado inteligente** basado en prioridades

### **Integraciones:**
- 🔗 **Slack notifications**
- 📊 **Prometheus metrics**  
- 📝 **Logging estructurado**
- 🌐 **API webhooks**

Este sistema demuestra perfectamente cómo implementar procesamiento asíncrono robusto en una aplicación Rails moderna. 🚀
