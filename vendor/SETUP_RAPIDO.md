# ⚡ Setup Rápido - TodoList App

## 🚀 **Inicio en 5 Minutos**

### **1. Prerrequisitos**
```bash
# Verificar versiones
ruby --version    # Debe ser 3.3.0
rails --version   # Debe ser 7.0.4.3
redis-server --version  # Cualquier versión reciente
```

### **2. Instalación**
```bash
# Clonar y setup
git clone <repository-url>
cd rails-interview
bin/setup
```

### **3. Iniciar Servicios**
```bash
# Terminal 1: Redis
redis-server

# Terminal 2: Rails
bin/puma

# Terminal 3: Sidekiq
bundle exec sidekiq
```

### **4. Acceder a la App**
- **Web**: http://localhost:3000
- **API**: http://localhost:3000/api
- **Sidekiq**: http://localhost:3000/sidekiq

---

## 🎯 **Demo Rápido**

### **Crear y Procesar Tareas**
```bash
# Crear datos de prueba
rails runner "
list = TodoList.create!(name: 'Demo List')
5.times { |i| list.todo_items.create!(description: \"Demo Task #{i+1}\", completed: false) }
puts \"✅ Lista creada: http://localhost:3000/todolists/#{list.id}\"
"
```

### **Ver Progreso en Tiempo Real**
1. Ir a la URL generada
2. Click en **"Iniciar Procesamiento"**
3. Ver mini barras de progreso en cada tarea
4. Abrir **consola del browser** (F12) para logs detallados

---

## 🐳 **Con Docker (Alternativa)**

### **Desarrollo**
```bash
# Todo en uno
docker-compose up --build

# Acceso: http://localhost:3000
```

### **Producción**
```bash
# Con Nginx
docker-compose -f docker-compose.prod.yml up --build

# Acceso: http://localhost:80
```

---

## 🔧 **Comandos Útiles**

### **Desarrollo**
```bash
# Tests
bin/rspec

# Consola Rails
rails console

# Limpiar jobs
rails runner "require 'sidekiq/api'; Sidekiq::Queue.new.clear"

# Ver logs en vivo
tail -f log/development.log
```

### **API Testing**
```bash
# Crear TodoList
curl -X POST http://localhost:3000/api/todolists \
  -H "Content-Type: application/json" \
  -d '{"name": "API Test List"}'

# Listar TodoLists
curl http://localhost:3000/api/todolists

# Auto-completar (background job)
curl -X POST http://localhost:3000/api/todolists/1/auto_complete
```

---

## 🎯 **Características Principales**

### ✅ **Lo que verás funcionando:**
- **CRUD completo** de listas y tareas
- **Mini barras de progreso** individuales por tarea
- **Procesamiento en tiempo real** sin reloads
- **Jobs en background** con Sidekiq
- **Logs detallados** en consola del browser y servidor

### 🔍 **Debugging**
- **Browser Console**: Logs de progreso en tiempo real
- **Server Console**: Logs detallados del job processing
- **Sidekiq Web**: Monitor de jobs en http://localhost:3000/sidekiq

---

## 🚨 **Problemas Comunes**

### **Redis no conecta**
```bash
# Instalar Redis
# macOS: brew install redis
# Ubuntu: sudo apt install redis-server

# Iniciar Redis
redis-server
```

### **Jobs no procesan**
```bash
# Verificar que Sidekiq esté corriendo
bundle exec sidekiq

# Limpiar cola si hay jobs colgados
rails runner "require 'sidekiq/api'; Sidekiq::Queue.new.clear"
```

### **Barras no aparecen**
```bash
# Verificar que Redis esté corriendo
redis-cli ping  # Debe responder "PONG"

# Revisar logs del browser (F12)
# Debe mostrar: "SIMPLE PROGRESS CONTROLLER CONNECTED!"
```

---

## 📋 **URLs Importantes**

- **Home**: http://localhost:3000
- **API Docs**: Ver `MANUAL_DE_CAMBIOS.md` para endpoints
- **Sidekiq**: http://localhost:3000/sidekiq
- **Health Check**: http://localhost:3000/api/todolists

---

## 🎉 **¡Listo!**

Si todo está funcionando, deberías poder:
1. ✅ Crear listas y tareas
2. ✅ Ver mini barras de progreso
3. ✅ Procesar tareas sin reload
4. ✅ Ver logs en consola del browser

**¡Disfruta explorando la aplicación!** 🚀
