import { Controller } from "@hotwired/stimulus"

// Conecta con data-controller="simple-progress"
export default class extends Controller {
  static targets = ["button", "container"]
  static values = { 
    url: String,
    pendingCount: Number
  }

  connect() {
    console.log("🚀 SIMPLE PROGRESS CONTROLLER CONNECTED!")
    console.log(`📊 Pending tasks: ${this.pendingCountValue}`)
    this.isProcessing = false
  }

  disconnect() {
    console.log("🔌 SIMPLE PROGRESS CONTROLLER DISCONNECTED!")
  }

  // Iniciar procesamiento
  start(event) {
    event.preventDefault()

    if (this.isProcessing) {
      console.log("⚠️ Processing already in progress")
      return
    }

    if (this.pendingCountValue === 0) {
      console.log("⚠️ No pending tasks to process")
      return
    }

    console.log("🚀 Starting simple progress processing...")
    this.isProcessing = true

    this.disableButton()
    this.startTaskProcessing()
  }

  // Iniciar procesamiento de tareas
  async startTaskProcessing() {
    try {
      console.log("📡 Sending AJAX request to start processing...")
      
      const response = await fetch(this.urlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
          'Accept': 'application/json'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      console.log("✅ Process started:", data)

      // Iniciar procesamiento visual de tareas
      this.processTasksVisually()

    } catch (error) {
      console.error("❌ Error starting process:", error)
      this.enableButton()
      this.isProcessing = false
    }
  }

  // Procesar tareas visualmente
  processTasksVisually() {
    console.log("🎯 Starting visual task processing...")
    
    // Obtener todas las tareas pendientes
    const pendingTasks = this.element.querySelectorAll('[data-controller*="task"][data-task-status-value="pending"]')
    console.log(`📋 Found ${pendingTasks.length} pending tasks`)

    if (pendingTasks.length === 0) {
      console.log("⚠️ No pending tasks found")
      this.enableButton()
      this.isProcessing = false
      return
    }

    // Procesar cada tarea secuencialmente
    this.processTaskSequentially(Array.from(pendingTasks), 0)
  }

  // Procesar tareas secuencialmente
  async processTaskSequentially(tasks, index) {
    if (index >= tasks.length) {
      console.log("🎉 All tasks processed!")
      this.enableButton()
      this.isProcessing = false
      return
    }

    const taskElement = tasks[index]
    const taskId = taskElement.getAttribute('data-task-task-id-value')
    
    console.log(`\n${'='.repeat(60)}`)
    console.log(`🔄 PROCESSING TASK ${index + 1}/${tasks.length}`)
    console.log(`📝 Task ID: ${taskId}`)
    console.log(`📊 PROGRESS: ${Math.round(((index) / tasks.length) * 100)}%`)
    console.log(`${'='.repeat(60)}\n`)

    // Obtener el controlador de la tarea
    const taskController = this.application.getControllerForElementAndIdentifier(taskElement, 'task')
    
    if (taskController) {
      // Iniciar procesamiento visual de la tarea
      taskController.processTask()
      
      // Esperar 2 segundos (como en el job real)
      await this.sleep(2000)
      
      // Marcar como completada
      taskController.completeTask()
      
      console.log(`✅ Task ${taskId} completed!`)
      
      // Procesar siguiente tarea después de una pequeña pausa
      setTimeout(() => {
        this.processTaskSequentially(tasks, index + 1)
      }, 500)
    } else {
      console.error(`❌ No task controller found for task ${taskId}`)
      // Continuar con la siguiente tarea
      setTimeout(() => {
        this.processTaskSequentially(tasks, index + 1)
      }, 100)
    }
  }

  // Función helper para sleep
  sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  // Deshabilitar botón
  disableButton() {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
      this.buttonTarget.innerHTML = `
        <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
        Procesando...
      `
    }
  }

  // Habilitar botón
  enableButton() {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = false
      this.buttonTarget.innerHTML = `
        <i class="bi bi-play-circle-fill me-2"></i>
        Iniciar Procesamiento
      `
    }
  }
}
