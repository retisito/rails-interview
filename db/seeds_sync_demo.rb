# frozen_string_literal: true

# Seeds para demostración de sincronización bidireccional
# Basado en el Plan de Acción Crunchloop

puts "🌱 Creando datos de demostración para Sincronización Bidireccional..."

# Limpiar datos existentes de sync
puts "🧹 Limpiando datos de sincronización existentes..."
ConflictResolutionTask.destroy_all
SyncSession.destroy_all

# Actualizar TodoLists existentes con campos de sync
puts "🔄 Configurando listas existentes para sincronización..."

# Lista 1: Habilitada para sync con datos simulados
list1 = TodoList.first
if list1
  list1.update!(
    sync_enabled: true,
    external_id: "ext_todolist_#{list1.id}_demo",
    synced_at: 2.hours.ago
  )
  
  # Actualizar algunos items con external_id
  list1.todo_items.limit(2).each_with_index do |item, index|
    item.update!(
      external_id: "ext_item_#{item.id}_#{index}",
      synced_at: 1.hour.ago
    )
  end
  
  puts "✅ Lista '#{list1.name}' configurada para sync"
end

# Lista 2: Habilitada pero necesita sync
list2 = TodoList.second
if list2
  list2.update!(
    sync_enabled: true,
    external_id: "ext_todolist_#{list2.id}_demo",
    synced_at: 1.day.ago  # Más antigua que updated_at
  )
  
  puts "✅ Lista '#{list2.name}' configurada (necesita sync)"
end

# Crear nueva lista específicamente para demo de sync
demo_list = TodoList.create!(
  name: "🔄 Demo Sincronización Bidireccional",
  sync_enabled: true,
  external_id: "ext_demo_sync_list_#{SecureRandom.hex(4)}",
  synced_at: nil  # Nunca sincronizada
)

# Agregar items a la lista demo
demo_items = [
  "Implementar motor de sincronización",
  "Configurar API externa cliente", 
  "Crear resolución de conflictos",
  "Dashboard de monitoreo",
  "Testing de integración"
]

demo_items.each_with_index do |description, index|
  item = demo_list.todo_items.create!(
    description: description,
    completed: index < 2, # Primeros 2 completados
    external_id: index.even? ? "ext_demo_item_#{index}" : nil,
    synced_at: index < 2 ? 30.minutes.ago : nil
  )
  
  puts "📝 Creado item: #{description}"
end

puts "✅ Lista demo creada: '#{demo_list.name}'"

# Crear sesiones de sincronización simuladas
puts "📊 Creando sesiones de sincronización de ejemplo..."

# Sesión exitosa reciente
successful_session = SyncSession.create!(
  todo_list: demo_list,
  status: 'completed',
  strategy: 'incremental_sync',
  started_at: 1.hour.ago,
  completed_at: 50.minutes.ago,
  local_changes_count: 3,
  remote_changes_count: 2,
  conflicts_count: 1,
  sync_results: {
    local_applied: 3,
    remote_applied: 2,
    conflicts_resolved: 1,
    errors: []
  }
)

# Sesión fallida
failed_session = SyncSession.create!(
  todo_list: list1,
  status: 'failed',
  strategy: 'full_sync',
  started_at: 3.hours.ago,
  completed_at: 3.hours.ago,
  local_changes_count: 5,
  remote_changes_count: 0,
  conflicts_count: 0,
  error_message: "External API timeout after 30 seconds",
  sync_results: {
    local_applied: 0,
    remote_applied: 0,
    conflicts_resolved: 0,
    errors: ["Timeout connecting to external API"]
  }
)

# Sesión en curso (simulada)
running_session = SyncSession.create!(
  todo_list: list2,
  status: 'running',
  strategy: 'batch_sync',
  started_at: 5.minutes.ago,
  local_changes_count: 4,
  remote_changes_count: 3,
  conflicts_count: 0
)

puts "✅ Sesiones de sincronización creadas"

# Crear conflictos de resolución de ejemplo
puts "⚠️ Creando conflictos de ejemplo..."

# Conflicto auto-resolvible
auto_conflict = ConflictResolutionTask.create!(
  sync_session: successful_session,
  conflict_type: 'data_conflict',
  status: 'pending',
  local_data: {
    'id' => demo_list.todo_items.first.id,
    'description' => 'Implementar motor de sincronización v2',
    'completed' => true,
    'updated_at' => 1.hour.ago.iso8601
  },
  remote_data: {
    'id' => demo_list.todo_items.first.external_id,
    'description' => 'Implementar motor de sincronización',
    'completed' => true,
    'updated_at' => 2.hours.ago.iso8601
  }
)

# Conflicto manual
manual_conflict = ConflictResolutionTask.create!(
  sync_session: successful_session,
  conflict_type: 'creation_conflict',
  status: 'pending',
  local_data: {
    'description' => 'Nueva tarea local',
    'completed' => false,
    'created_at' => 30.minutes.ago.iso8601
  },
  remote_data: {
    'description' => 'Nueva tarea remota diferente',
    'completed' => false,
    'created_at' => 25.minutes.ago.iso8601
  }
)

# Conflicto ya resuelto
resolved_conflict = ConflictResolutionTask.create!(
  sync_session: successful_session,
  conflict_type: 'data_conflict',
  status: 'auto_resolved',
  resolved_at: 45.minutes.ago,
  resolution_strategy: 'automatic',
  local_data: {
    'description' => 'Tarea con conflicto',
    'completed' => false
  },
  remote_data: {
    'description' => 'Tarea con conflicto',
    'completed' => true
  },
  resolution_data: {
    'description' => 'Tarea con conflicto',
    'completed' => true,
    'resolution_reason' => 'completed=true wins'
  }
)

puts "✅ Conflictos de ejemplo creados"

# Estadísticas finales
puts "\n" + "="*60
puts "📊 RESUMEN DE DATOS DE DEMOSTRACIÓN"
puts "="*60

puts "📋 TodoLists:"
TodoList.find_each do |list|
  status = list.sync_enabled? ? "✅ Sync habilitado" : "❌ Sync deshabilitado"
  puts "  • #{list.name}: #{status}"
  puts "    - Items: #{list.todo_items.count} (#{list.todo_items.completed.count} completados)"
  puts "    - External ID: #{list.external_id || 'N/A'}"
  puts "    - Última sync: #{list.synced_at&.strftime('%d/%m/%Y %H:%M') || 'Nunca'}"
  puts "    - Estado: #{list.sync_status.humanize}"
end

puts "\n🔄 Sesiones de Sincronización:"
puts "  • Total: #{SyncSession.count}"
puts "  • Completadas: #{SyncSession.completed.count}"
puts "  • Fallidas: #{SyncSession.failed.count}"
puts "  • En curso: #{SyncSession.running.count}"

puts "\n⚠️ Conflictos:"
puts "  • Total: #{ConflictResolutionTask.count}"
puts "  • Pendientes: #{ConflictResolutionTask.pending.count}"
puts "  • Auto-resueltos: #{ConflictResolutionTask.auto_resolved.count}"
puts "  • Resueltos manualmente: #{ConflictResolutionTask.resolved.count}"

puts "\n🚀 URLs de Acceso:"
puts "  • Sync Dashboard: http://localhost:3000/sync_dashboard"
puts "  • Lista Demo: http://localhost:3000/todolists/#{demo_list.id}"
puts "  • API Health: http://localhost:3000/sync_dashboard/api_health"

puts "\n✅ ¡Datos de demostración creados exitosamente!"
puts "🎯 Ahora puedes explorar el Dashboard de Sincronización"
puts "="*60
