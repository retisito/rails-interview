import { Controller } from "@hotwired/stimulus"

// Conecta con data-controller="task"
export default class extends Controller {
  static targets = ["progressContainer", "bar", "percentage", "status"]
  static values = { 
    taskId: Number,
    status: String
  }

  connect() {
    console.log(`📋 Task controller connected for task ${this.taskIdValue}`)
    this.isProcessing = false
  }

  disconnect() {
    console.log(`📋 Task controller disconnected for task ${this.taskIdValue}`)
  }

  // Iniciar el procesamiento de esta tarea
  startProcessing() {
    console.log(`🚀 Starting processing for task ${this.taskIdValue}`)
    
    this.isProcessing = true
    this.statusValue = 'processing'
    
    // Mostrar la mini barra de progreso
    if (this.hasProgressContainerTarget) {
      this.progressContainerTarget.style.display = 'block'
    }
    
    // Actualizar estado visual
    this.updateStatus('Procesando...', 'warning')
    
    // Iniciar progreso desde 0
    this.updateProgress(0)
    
    // Simular progreso gradual durante 2 segundos
    this.simulateProgress()
  }

  // Simular progreso gradual
  simulateProgress() {
    const duration = 2000 // 2 segundos
    const steps = 20 // 20 pasos
    const stepDuration = duration / steps
    let currentStep = 0

    console.log(`⏱️ Simulating progress for task ${this.taskIdValue} - ${steps} steps over ${duration}ms`)

    this.progressInterval = setInterval(() => {
      currentStep++
      const percentage = Math.round((currentStep / steps) * 100)
      
      console.log(`📊 Task ${this.taskIdValue} progress: ${percentage}%`)
      this.updateProgress(percentage)
      
      if (currentStep >= steps) {
        console.log(`✅ Task ${this.taskIdValue} progress simulation completed`)
        clearInterval(this.progressInterval)
        // No completar automáticamente, esperar señal del servidor
      }
    }, stepDuration)
  }

  // Actualizar progreso de la mini barra
  updateProgress(percentage) {
    console.log(`📊 Updating task ${this.taskIdValue} progress to ${percentage}%`)
    
    if (this.hasBarTarget) {
      this.barTarget.style.width = `${percentage}%`
      this.barTarget.setAttribute('aria-valuenow', percentage)
    }
    
    if (this.hasPercentageTarget) {
      this.percentageTarget.textContent = `${percentage}%`
    }
  }

  // Marcar tarea como completada
  markCompleted() {
    console.log(`✅ Marking task ${this.taskIdValue} as completed`)
    
    this.isProcessing = false
    this.statusValue = 'completed'
    
    // Limpiar intervalo si existe
    if (this.progressInterval) {
      clearInterval(this.progressInterval)
    }
    
    // Ocultar mini barra
    if (this.hasProgressContainerTarget) {
      this.progressContainerTarget.style.display = 'none'
    }
    
    // Actualizar estado visual
    this.updateStatus('Completada', 'success')
    
    // Tachar el texto
    this.element.classList.add('task-completed')
    
    // Agregar efecto visual de completado
    this.addCompletionEffect()
  }

  // Actualizar estado visual
  updateStatus(message, type) {
    if (this.hasStatusTarget) {
      this.statusTarget.style.display = 'inline-block'
      
      const icon = this.statusTarget.querySelector('i')
      const text = this.statusTarget.querySelector('small')
      
      if (icon && text) {
        // Limpiar clases anteriores
        icon.className = 'me-1'
        text.className = 'fw-bold'
        
        // Agregar nuevas clases según el tipo
        switch (type) {
          case 'warning':
            icon.classList.add('bi', 'bi-hourglass-split', 'text-warning')
            text.classList.add('text-warning')
            break
          case 'success':
            icon.classList.add('bi', 'bi-check-circle-fill', 'text-success')
            text.classList.add('text-success')
            break
          case 'info':
            icon.classList.add('bi', 'bi-info-circle', 'text-info')
            text.classList.add('text-info')
            break
          default:
            icon.classList.add('bi', 'bi-clock', 'text-muted')
            text.classList.add('text-muted')
        }
        
        text.textContent = message
      }
    }
  }

  // Efecto visual de completado
  addCompletionEffect() {
    // Agregar clase CSS para transición suave
    this.element.style.transition = 'all 0.3s ease'
    this.element.style.backgroundColor = '#d4edda'
    
    // Volver al color normal después de un momento
    setTimeout(() => {
      this.element.style.backgroundColor = ''
    }, 1000)
  }

  // Método público para ser llamado desde el controlador principal
  processTask() {
    if (!this.isProcessing && this.statusValue !== 'completed') {
      this.startProcessing()
    }
  }

  // Método público para marcar como completado desde el servidor
  completeTask() {
    if (this.isProcessing) {
      this.markCompleted()
    }
  }
}
