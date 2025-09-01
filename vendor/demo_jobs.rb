#!/usr/bin/env ruby

# Demo script para probar Active Jobs con Sidekiq
# Ejecutar con: rails runner demo_jobs.rb

puts "🚀 Demo: Active Jobs con Sidekiq"
puts "=" * 50

# Asegurar que tenemos datos de ejemplo
puts "\n📋 Preparando datos de ejemplo..."

# Encontrar o crear una lista con tareas
todo_list = TodoList.find_by(name: 'Demo Jobs List')
if todo_list.nil?
  todo_list = TodoList.create!(name: 'Demo Jobs List')
  puts "✅ Creada nueva lista: #{todo_list.name}"
else
  puts "✅ Usando lista existente: #{todo_list.name}"
end

# Agregar algunas tareas pendientes si no las hay
if todo_list.todo_items.pending.count < 3
  [
    "Configurar servidor de producción",
    "Implementar autenticación de usuarios", 
    "Crear sistema de notificaciones",
    "Optimizar consultas de base de datos",
    "Escribir documentación de API"
  ].each do |description|
    todo_list.todo_items.create!(description: description, completed: false)
  end
  puts "✅ Agregadas tareas de ejemplo"
end

puts "\n📊 Estado actual:"
puts "   - Total de tareas: #{todo_list.todo_items.count}"
puts "   - Pendientes: #{todo_list.todo_items.pending.count}"
puts "   - Completadas: #{todo_list.todo_items.completed.count}"

# Demo 1: Completado simple con delay
puts "\n🎯 Demo 1: Completado Automático Simple"
puts "-" * 40

puts "⏳ Programando completado automático en 3 segundos..."
job_info = AutoCompletionService.schedule_completion(todo_list, 3)

puts "✅ Job programado:"
puts "   - Job ID: #{job_info[:job_id]}"
puts "   - Delay: #{job_info[:delay_seconds]} segundos"
puts "   - Estimado para: #{job_info[:estimated_completion_at]}"

puts "\n⏱️  Esperando completado..."
sleep(5) # Esperar a que termine el job

# Refresh para ver los cambios
todo_list.reload
puts "📊 Estado después del job:"
puts "   - Pendientes: #{todo_list.todo_items.pending.count}"
puts "   - Completadas: #{todo_list.todo_items.completed.count}"

# Crear más tareas para el siguiente demo
puts "\n🔄 Recreando tareas para siguiente demo..."
todo_list.todo_items.update_all(completed: false)

# Demo 2: Completado por lotes
puts "\n🎯 Demo 2: Completado por Lotes"
puts "-" * 40

batch_info = AutoCompletionService.schedule_batch_completion(todo_list, 2, 3)

puts "✅ Jobs en lote programados:"
puts "   - Total de lotes: #{batch_info[:total_batches]}"
puts "   - Total de tareas: #{batch_info[:total_items]}"

batch_info[:jobs].each_with_index do |job, index|
  puts "   Lote #{job[:batch_number]}: #{job[:item_ids].count} items, delay #{job[:delay_seconds]}s"
end

puts "\n⏱️  Esperando completado por lotes..."
sleep(batch_info[:total_batches] * 3 + 5)

# Ver resultado final
todo_list.reload
puts "\n📊 Estado final:"
puts "   - Pendientes: #{todo_list.todo_items.pending.count}"
puts "   - Completadas: #{todo_list.todo_items.completed.count}"

# Estadísticas de Sidekiq
puts "\n📈 Estadísticas de Sidekiq:"
stats = AutoCompletionService.get_job_stats
puts "   - Jobs procesados: #{stats[:processed]}"
puts "   - Jobs fallidos: #{stats[:failed]}"
puts "   - Workers ocupados: #{stats[:busy]}"
puts "   - Jobs en cola: #{stats[:enqueued]}"

puts "\n🎉 Demo completado!"
puts "💡 Para ver más detalles, visita: http://localhost:3000/sidekiq"
puts "🌐 Para probar la UI web: http://localhost:3000/todolists/#{todo_list.id}"
