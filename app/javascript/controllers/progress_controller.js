import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "bar", "percentage", "message", "button"]
  static values = { 
    url: String,
    pendingCount: Number,
    sessionId: String 
  }

  connect() {
    console.log("🎯 PROGRESS CONTROLLER CONNECTED!")
    console.log("📊 Targets available:", this.targets)
    console.log("🔧 Values available:", this.values)
    console.log("🎪 Element:", this.element)
    this.isProcessing = false
    
    // Si ya hay session_id (viene de redirect), mostrar barra
    if (this.sessionIdValue) {
      console.log(`📡 Existing session detected: ${this.sessionIdValue}`)
      this.showProgressBar()
      this.connectTurboStream()
    }
  }

  // Acción cuando se hace click en "Iniciar Procesamiento"
  start(event) {
    event.preventDefault()
    
    if (this.isProcessing) {
      console.log("⚠️ Processing already in progress")
      return
    }

    console.log("🚀 Starting progressive process...")
    this.isProcessing = true
    
    // Deshabilitar botón y mostrar loading
    this.disableButton()
    
    // Mostrar barra inmediatamente
    this.showProgressBar()
    this.resetProgress()
    
    // Enviar request AJAX para NO recargar la página
    this.sendStartRequest()
  }

  // Enviar request AJAX al servidor
  async sendStartRequest() {
    try {
      const response = await fetch(this.urlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
          'Accept': 'application/json'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

      const data = await response.json()
      console.log("✅ Process started:", data)
      
      // Guardar session_id y usar método confiable
      this.sessionIdValue = data.session_id
      
      // Mostrar mensaje inicial inmediatamente
      this.updateProgress(0, `Iniciando procesamiento de ${data.pending_count} tareas...`)
      this.showToast(`Procesando ${data.pending_count} tareas...`, 'info')
      
      // Conectar Turbo Stream de forma confiable (con reload mínimo)
      this.connectTurboStreamReliable()
      
    } catch (error) {
      console.error("❌ Error starting process:", error)
      this.showToast('Error al iniciar el procesamiento', 'error')
      this.enableButton()
      this.isProcessing = false
    }
  }

  // Conectar a Turbo Stream - versión simplificada (con reload)
  connectTurboStream() {
    console.log(`📡 Connecting to Turbo Stream: progress_${this.sessionIdValue}`)
    
    // En lugar de crear dinámicamente, recargar con session_id
    const currentUrl = new URL(window.location)
    currentUrl.searchParams.set('session_id', this.sessionIdValue)
    
    // Solo recargar si no estamos ya en la URL correcta
    if (window.location.href !== currentUrl.toString()) {
      console.log("🔄 Reloading with session_id for Turbo Stream connection")
      window.location.href = currentUrl.toString()
    } else {
      console.log("✅ Already connected to correct session")
    }
  }

  // Conectar a Turbo Stream dinámicamente SIN reload - método correcto
  connectTurboStreamDynamic() {
    console.log(`📡 Connecting to Turbo Stream DYNAMICALLY: progress_${this.sessionIdValue}`)
    
    // Método 1: Actualizar URL sin reload usando history API
    const currentUrl = new URL(window.location)
    currentUrl.searchParams.set('session_id', this.sessionIdValue)
    
    // Actualizar URL sin recargar
    window.history.replaceState({}, '', currentUrl.toString())
    console.log("🔄 URL updated with session_id (no reload)")
    
    // Método 2: Crear conexión manualmente usando Turbo
    this.createTurboStreamConnection()
  }

  // Crear conexión Turbo Stream manualmente
  createTurboStreamConnection() {
    console.log("🔌 Creating manual Turbo Stream connection")
    
    // Importar Turbo si está disponible
    if (window.Turbo && window.Turbo.StreamSource) {
      const channelName = `progress_${this.sessionIdValue}`
      console.log(`📺 Creating StreamSource for channel: ${channelName}`)
      
      // Crear StreamSource manualmente
      this.streamSource = new window.Turbo.StreamSource(`/cable?channel=${channelName}`)
      this.streamSource.start()
      
      console.log("✅ Manual Turbo Stream connection created")
    } else {
      console.log("⚠️ Turbo.StreamSource not available, falling back to simple method")
      this.fallbackTurboStream()
    }
  }

  // Método de fallback más simple
  fallbackTurboStream() {
    console.log("🔄 Using fallback: will reload page with session_id")
    
    setTimeout(() => {
      const currentUrl = new URL(window.location)
      currentUrl.searchParams.set('session_id', this.sessionIdValue)
      window.location.href = currentUrl.toString()
    }, 1000) // Dar tiempo para que se vea la barra
  }

  // Método más confiable: mostrar barra inmediatamente, luego conectar
  connectTurboStreamReliable() {
    console.log("🎯 Using reliable Turbo Stream connection method")
    
    // Dar tiempo para que el usuario vea la barra y el mensaje inicial
    setTimeout(() => {
      console.log("⏰ Now connecting to Turbo Stream after showing initial progress")
      
      const currentUrl = new URL(window.location)
      currentUrl.searchParams.set('session_id', this.sessionIdValue)
      
      console.log("🔄 Reloading with session_id for reliable Turbo Stream connection")
      window.location.href = currentUrl.toString()
    }, 1500) // 1.5 segundos para ver el feedback inicial
  }

  // Mostrar barra de progreso
  showProgressBar() {
    if (this.hasContainerTarget) {
      this.containerTarget.style.display = 'block'
      this.containerTarget.scrollIntoView({ behavior: 'smooth', block: 'center' })
      console.log("✅ Progress bar shown")
    }
  }

  // Resetear progreso a 0
  resetProgress() {
    this.updateProgress(0, "Preparando procesamiento...")
  }

  // Actualizar progreso (puede ser llamado desde Turbo Stream)
  updateProgress(percentage, message) {
    console.log(`\n${'='.repeat(60)}`)
    console.log(`📊 PROGRESO ACTUALIZADO: ${percentage}%`)
    console.log(`💬 Mensaje: ${message}`)
    console.log(`⏰ Timestamp: ${new Date().toLocaleTimeString()}`)
    
    if (this.hasBarTarget) {
      this.barTarget.style.width = `${percentage}%`
      this.barTarget.setAttribute('aria-valuenow', percentage)
      console.log(`🎯 Barra actualizada: width = ${percentage}%`)
    }
    
    if (this.hasPercentageTarget) {
      this.percentageTarget.textContent = `${percentage}%`
      console.log(`🔢 Texto porcentaje actualizado: ${percentage}%`)
    }
    
    if (this.hasMessageTarget) {
      this.messageTarget.textContent = message
      console.log(`📝 Mensaje actualizado: ${message}`)
    }
    
    console.log(`${'='.repeat(60)}\n`)
  }

  // Procesamiento completado
  completed(message = "¡Procesamiento completado! 🎉") {
    console.log("🎉 Processing completed")
    this.updateProgress(100, message)
    this.enableButton()
    this.isProcessing = false
    this.showToast(message, 'success')
    
    // Recargar página después de 3 segundos para ver tareas actualizadas
    setTimeout(() => {
      window.location.reload()
    }, 3000)
  }

  // Error en el procesamiento
  error(message = "Error en el procesamiento") {
    console.log("❌ Processing error")
    this.updateProgress(0, message)
    this.enableButton()
    this.isProcessing = false
    this.showToast(message, 'error')
  }

  // Deshabilitar botón
  disableButton() {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
      this.buttonTarget.innerHTML = '<i class="spinner-border spinner-border-sm me-2"></i>Procesando...'
    }
  }

  // Habilitar botón
  enableButton() {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = false
      this.buttonTarget.innerHTML = '<i class="bi bi-play-circle-fill me-2"></i>Iniciar Procesamiento'
    }
  }

  // Mostrar toast notification
  showToast(message, type = 'info') {
    const toast = document.createElement('div')
    toast.className = `alert alert-${type === 'error' ? 'danger' : type === 'success' ? 'success' : 'info'} position-fixed`
    toast.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;'
    toast.innerHTML = `
      <i class="bi bi-${type === 'error' ? 'exclamation-triangle' : type === 'success' ? 'check-circle' : 'info-circle'} me-2"></i>
      ${message}
      <button type="button" class="btn-close float-end" onclick="this.parentElement.remove()"></button>
    `
    
    document.body.appendChild(toast)
    
    // Auto-remove después de 5 segundos
    setTimeout(() => {
      if (toast.parentNode) {
        toast.remove()
      }
    }, 5000)
  }

  // Logging de eventos Turbo Stream para debugging
  turboStreamReceived(event) {
    console.log("\n🔥 TURBO STREAM RECIBIDO:")
    console.log("📦 Event detail:", event.detail)
    console.log("🎯 Target:", event.detail?.target)
    console.log("📄 Action:", event.detail?.action)
    console.log("⏰ Timestamp:", new Date().toLocaleTimeString())
    
    // Intentar extraer porcentaje del HTML si es posible
    if (event.detail?.template) {
      const percentageMatch = event.detail.template.match(/(\d+)%/)
      if (percentageMatch) {
        console.log(`📊 PORCENTAJE DETECTADO EN STREAM: ${percentageMatch[1]}%`)
      }
    }
  }

  turboStreamRendered(event) {
    console.log("\n✅ TURBO STREAM RENDERIZADO:")
    console.log("📦 Event detail:", event.detail)
    console.log("⏰ Timestamp:", new Date().toLocaleTimeString())
    
    // Verificar si se actualizó la barra de progreso
    if (this.hasBarTarget) {
      const currentWidth = this.barTarget.style.width
      console.log(`🎯 Ancho actual de la barra: ${currentWidth}`)
    }
    
    if (this.hasPercentageTarget) {
      const currentPercentage = this.percentageTarget.textContent
      console.log(`🔢 Porcentaje mostrado: ${currentPercentage}`)
    }
  }
}
