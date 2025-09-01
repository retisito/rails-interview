// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

console.log("🚀 Loading controllers...")

// Import controllers manually
import ProgressController from "controllers/progress_controller"
import TaskController from "controllers/task_controller"
import SimpleProgressController from "controllers/simple_progress_controller"

console.log("📦 ProgressController imported:", ProgressController)
console.log("📦 TaskController imported:", TaskController)
console.log("📦 SimpleProgressController imported:", SimpleProgressController)

// Register controllers
application.register("progress", ProgressController)
application.register("task", TaskController)
application.register("simple-progress", SimpleProgressController)

console.log("✅ Progress controller registered")
console.log("✅ Task controller registered")
console.log("✅ Simple Progress controller registered")
console.log("🎯 Controllers loaded:", application.router.modulesByIdentifier.size)
console.log("📋 All controllers:", Array.from(application.router.modulesByIdentifier.keys()))