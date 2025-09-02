# Rails Interview - TodoList API & Web Application

[![Open in Coder](https://dev.crunchloop.io/open-in-coder.svg)](https://dev.crunchloop.io/templates/fly-containers/workspace?param.Git%20Repository=git@github.com:crunchloop/rails-interview.git)

This is a comprehensive Todo List application built in Ruby on Rails 7, featuring both a REST API and a modern web interface with real-time progress tracking.

## 🚀 Features Implemented

### ✅ **Core API (RESTful)**
- **CRUD Operations** for TodoLists and TodoItems
- **JSON API** with Jbuilder templates
- **API Authentication** bypass for development
- **Comprehensive Testing** with RSpec
- **Postman Collection** compatible endpoints

### ✅ **Web Interface (HTML CRUD)**
- **Modern Bootstrap 5** responsive design
- **Complete CRUD** operations for lists and items
- **Interactive UI** with icons and visual feedback
- **Form validation** and error handling

### ✅ **Background Jobs & Real-time Processing**
- **Sidekiq** for background job processing
- **Redis** integration for job queues
- **Progressive completion** with simulated delays
- **Real-time progress tracking** with individual task bars

### ✅ **Advanced UI Features**
- **Hotwire (Turbo + Stimulus)** for modern interactions
- **Individual progress bars** for each task
- **Real-time visual feedback** during processing
- **No page reloads** - seamless user experience
- **Console logging** for debugging and monitoring

### ✅ **Docker Support**
- **Multi-stage builds** for production optimization
- **Docker Compose** for development and production
- **Nginx** reverse proxy configuration
- **PostgreSQL** for production database
- **Redis** for caching and job queues

### ✅ **Bidirectional Sync System** 🆕
- **Complete sync engine** for external API integration
- **Conflict resolution** with multiple strategies
- **Real-time dashboard** for monitoring and control
- **Background job processing** with Sidekiq
- **External API client** with error handling and retry logic
- **Comprehensive tracking** of sync sessions and conflicts

## 📋 **Quick Start**

### Prerequisites
- Ruby 3.3.0
- Rails 7.0.4.3
- Redis server
- SQLite3 (development) / PostgreSQL (production)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd rails-interview

# Install dependencies
bin/setup

# Start Redis (required for background jobs)
redis-server

# Start the application
bin/puma

# In another terminal, start Sidekiq
bundle exec sidekiq
```

### Access the Application
- **Web Interface**: http://localhost:3000
- **API Base URL**: http://localhost:3000/api
- **Sync Dashboard**: http://localhost:3000/sync_dashboard 🆕
- **API Health Check**: http://localhost:3000/sync_dashboard/api_health 🆕
- **Sidekiq Web UI**: http://localhost:3000/sidekiq

## 🔧 **Technical Implementation Details**

### **1. API Endpoints**

#### TodoLists
```
GET    /api/todolists           # List all todo lists
POST   /api/todolists           # Create a new todo list
GET    /api/todolists/:id       # Get a specific todo list
PUT    /api/todolists/:id       # Update a todo list
DELETE /api/todolists/:id       # Delete a todo list
POST   /api/todolists/:id/auto_complete  # Auto-complete all items
```

#### TodoItems
```
GET    /api/todolists/:list_id/todos           # List items in a todo list
POST   /api/todolists/:list_id/todos           # Create a new todo item
GET    /api/todolists/:list_id/todos/:id       # Get a specific todo item
PUT    /api/todolists/:list_id/todos/:id       # Update a todo item
DELETE /api/todolists/:list_id/todos/:id       # Delete a todo item
```

### **2. Background Jobs**

#### Progressive Completion Job
- **Purpose**: Simulate high-load processing with real-time progress
- **Duration**: 2 seconds per task
- **Features**: 
  - Real-time progress broadcasting via Turbo Streams
  - Individual task completion tracking
  - Visual progress bars for each task
  - Console logging for monitoring

```ruby
# Usage
ProgressiveCompletionJob.perform_later(todo_list_id, session_id)
```

### **3. Real-time Features**

#### Stimulus Controllers
- **`simple_progress_controller.js`**: Manages overall progress flow
- **`task_controller.js`**: Handles individual task progress bars
- **Features**:
  - AJAX requests without page reloads
  - Sequential task processing visualization
  - Real-time progress updates (0% to 100%)
  - Visual completion effects

#### Turbo Streams
- **Real-time updates** via Action Cable and Redis
- **Individual task updates** when completed
- **Progress bar synchronization** with backend jobs

### **4. UI Components**

#### Progress Visualization
- **Main progress bar**: Overall completion status
- **Individual task bars**: Per-task progress (0-100% over 2 seconds)
- **Status indicators**: Pending → Processing → Completed
- **Visual effects**: Color changes, animations, strikethrough text

#### Responsive Design
- **Bootstrap 5** components and utilities
- **Flexbox layouts** for proper alignment
- **Mobile-friendly** responsive design
- **Accessibility features** with proper ARIA attributes

## 🐳 **Docker Deployment**

### Development
```bash
# Build and start all services
docker-compose up --build

# Access the application
# Web: http://localhost:3000
# API: http://localhost:3000/api
```

### Production
```bash
# Build and start production services
docker-compose -f docker-compose.prod.yml up --build

# Access via Nginx reverse proxy
# Web: http://localhost:80
```

### Services
- **Rails App**: Main application server
- **PostgreSQL**: Production database
- **Redis**: Job queues and caching
- **Nginx**: Reverse proxy and static file serving
- **Sidekiq**: Background job processing

## 🧪 **Testing**

### Run Tests
```bash
# Run all tests
bin/rspec

# Run specific test files
bin/rspec spec/controllers/api/todo_lists_controller_spec.rb
```

### Test Coverage
- **API Controllers**: Complete CRUD operations
- **Model Validations**: TodoList and TodoItem models
- **Background Jobs**: Progressive completion functionality

## 📊 **Monitoring & Debugging**

### Console Logging
The application provides extensive console logging for debugging:

```javascript
// Browser Console (during progress)
🚀 SIMPLE PROGRESS CONTROLLER CONNECTED!
📋 Task controller connected for task 123
🔄 PROCESSING TASK 1/5 - PROGRESS: 0%
📊 Task 123 progress: 5%, 10%, 15%... 100%
✅ Task 123 completed!
```

```ruby
# Server Console (Rails logs)
🚀 INICIANDO PROCESAMIENTO PROGRESIVO
📋 Total de tareas: 5
⏱️ Tiempo estimado: 10 segundos
🔄 PROCESANDO TAREA 1/5
📊 PROGRESO: 20% (1/5 tareas completadas)
✅ Tarea completada: "Task description"
🎉 PROCESAMIENTO COMPLETADO AL 100%
```

### Sidekiq Web Interface
Monitor background jobs at `http://localhost:3000/sidekiq`:
- **Queue status** and job counts
- **Failed jobs** with retry functionality
- **Job execution times** and statistics

## 🔄 **Development Workflow**

### Key Files Modified/Created

#### Backend
- `app/jobs/progressive_completion_job.rb` - Background job with progress tracking
- `app/controllers/todo_lists_controller.rb` - HTML CRUD and progress endpoints
- `app/controllers/api/todo_lists_controller.rb` - API endpoints
- `app/models/todo_item.rb` - Enhanced with scopes and validations

#### Frontend
- `app/javascript/controllers/simple_progress_controller.js` - Main progress management
- `app/javascript/controllers/task_controller.js` - Individual task progress
- `app/views/todo_lists/` - Complete HTML interface
- `app/views/todo_lists/_todo_item.html.erb` - Task component with progress bars

#### Configuration
- `config/routes.rb` - API and web routes
- `config/cable.yml` - Action Cable configuration
- `Gemfile` - Dependencies (Sidekiq, Redis, etc.)
- `docker-compose.yml` - Development containers
- `docker-compose.prod.yml` - Production deployment

## 🎯 **Usage Examples**

### Web Interface
1. Visit `http://localhost:3000`
2. Create a new TodoList
3. Add multiple TodoItems
4. Click "Iniciar Procesamiento" to see real-time progress
5. Watch individual task progress bars fill up over 2 seconds each

### API Usage
```bash
# Create a TodoList
curl -X POST http://localhost:3000/api/todolists \
  -H "Content-Type: application/json" \
  -d '{"name": "My Todo List"}'

# Add TodoItems
curl -X POST http://localhost:3000/api/todolists/1/todos \
  -H "Content-Type: application/json" \
  -d '{"description": "Task 1", "completed": false}'

# Auto-complete all items (background job)
curl -X POST http://localhost:3000/api/todolists/1/auto_complete
```

## 🔄 **Bidirectional Sync System** 🆕

### **Overview**
This application includes a complete bidirectional synchronization system that demonstrates enterprise-level integration patterns. The system is based on the **Crunchloop Action Plan** and implements the **Rails Hybrid Intelligent** approach.

### **Key Components**

#### **1. Sync Engine (`app/services/sync_engine.rb`)**
- **Bidirectional sync** between local and external APIs
- **Conflict detection** and resolution strategies
- **Change tracking** with checksums for optimization
- **Error handling** with automatic retry logic

#### **2. External API Client (`app/services/external_api_client.rb`)**
- **HTTP client** with comprehensive error handling
- **Rate limiting** and retry mechanisms
- **Health checks** and connectivity monitoring
- **Simulation mode** for development and testing

#### **3. Background Processing (`app/jobs/bidirectional_sync_job.rb`)**
- **Sidekiq integration** for async processing
- **Retry strategies** with exponential backoff
- **Performance monitoring** and metrics collection
- **Real-time notifications** via Turbo Streams

#### **4. Conflict Resolution (`app/models/conflict_resolution_task.rb`)**
- **Multiple resolution strategies**: `last_write_wins`, `merge_changes`, `manual_resolution`
- **Auto-resolution** for simple conflicts
- **Manual review** for complex conflicts
- **Priority scoring** and queue management

#### **5. Sync Dashboard (`app/controllers/sync_dashboard_controller.rb`)**
- **Real-time monitoring** of sync operations
- **Control interface** for enabling/disabling sync per list
- **Conflict management** and resolution tools
- **Performance metrics** and health monitoring

### **Sync Strategies**

| Strategy | Description | Use Case |
|----------|-------------|----------|
| `incremental_sync` | Sync only changed items | Regular updates |
| `full_sync` | Complete data synchronization | Initial setup |
| `batch_sync` | Process multiple changes together | Bulk operations |
| `real_time_sync` | Immediate sync on changes | Critical updates |

### **Conflict Resolution Strategies**

| Strategy | Description | When to Use |
|----------|-------------|-------------|
| `last_write_wins` | Use most recent timestamp | Simple conflicts |
| `merge_changes` | Combine both versions | Text conflicts |
| `external_priority` | External API wins | External source of truth |
| `local_priority` | Local changes win | Local source of truth |
| `manual_resolution` | Human intervention required | Complex conflicts |

### **Usage Examples**

#### **Enable Sync for a TodoList**
```ruby
# In Rails console
list = TodoList.find(1)
list.enable_sync!(external_id: "ext_list_123")
```

#### **Trigger Manual Sync**
```ruby
# Trigger sync with specific strategy
list.trigger_sync!(
  strategy: 'incremental_sync',
  conflict_resolution: 'last_write_wins'
)
```

#### **Check Sync Status**
```ruby
# Get sync statistics
stats = list.sync_stats
puts "Status: #{stats[:status]}"
puts "Last synced: #{stats[:last_synced]}"
puts "Needs sync: #{stats[:needs_sync]}"
```

#### **Resolve Conflicts**
```ruby
# Auto-resolve pending conflicts
ConflictResolutionTask.auto_resolve_pending!

# Manual resolution
conflict = ConflictResolutionTask.pending.first
conflict.manual_resolve!(
  { description: "Merged description", completed: true },
  resolved_by: "admin"
)
```

### **Dashboard Features**

#### **Real-time Monitoring**
- **API Health Status** with latency metrics
- **Sync Statistics** with success rates
- **Active Sessions** and their progress
- **Pending Conflicts** requiring attention

#### **Control Interface**
- **Enable/Disable Sync** per TodoList
- **Trigger Manual Sync** with strategy selection
- **Conflict Resolution** tools
- **Performance Metrics** and analytics

#### **URLs**
- **Main Dashboard**: http://localhost:3000/sync_dashboard
- **API Health**: http://localhost:3000/sync_dashboard/api_health
- **Statistics**: http://localhost:3000/sync_dashboard/stats
- **Sessions**: http://localhost:3000/sync_dashboard/sessions
- **Conflicts**: http://localhost:3000/sync_dashboard/conflicts

### **Demo Data**
Run the demo data script to see the sync system in action:
```bash
rails runner db/seeds_sync_demo.rb
```

This creates:
- **3 TodoLists** with sync enabled
- **Sample sync sessions** (completed, failed, running)
- **Conflict examples** for testing resolution
- **External API simulation** data

## 🛠️ **Technology Stack**

### Backend
- **Ruby 3.3.0** - Programming language
- **Rails 7.0.4.3** - Web framework
- **Sidekiq 7.3.9** - Background job processing
- **Redis** - Job queues and Action Cable
- **SQLite3** (dev) / **PostgreSQL** (prod) - Database
- **Jbuilder** - JSON API templates

### Frontend
- **Hotwire (Turbo + Stimulus)** - Modern Rails frontend
- **Bootstrap 5** - CSS framework
- **JavaScript ES6+** - Client-side logic
- **Action Cable** - Real-time communication

### DevOps
- **Docker & Docker Compose** - Containerization
- **Nginx** - Reverse proxy
- **RSpec** - Testing framework

## 🚨 **Known Issues & Solutions**

### Issue: Progress bar not updating
**Solution**: Ensure Redis is running and Action Cable is properly mounted

### Issue: Background jobs not processing
**Solution**: Start Sidekiq with `bundle exec sidekiq`

### Issue: CSRF token errors
**Solution**: API controllers inherit from `Api::BaseController` which skips CSRF

## 📈 **Performance Considerations**

- **Background Jobs**: Heavy processing moved to Sidekiq workers
- **Real-time Updates**: Efficient Turbo Stream broadcasting
- **Database**: Proper indexing on foreign keys
- **Caching**: Redis integration for session storage
- **Asset Pipeline**: Optimized JavaScript and CSS loading

## 🔮 **Future Enhancements**

- [ ] User authentication and authorization
- [ ] WebSocket scaling for multiple users
- [ ] Progressive Web App (PWA) features
- [ ] Advanced filtering and search
- [ ] Email notifications for completed tasks
- [ ] Analytics and reporting dashboard

## 📞 **Contact**

- Santiago Doldán (sdoldan@crunchloop.io)

## 🏢 **About Crunchloop**

![crunchloop](https://s3.amazonaws.com/crunchloop.io/logo-blue.png)

We strongly believe in giving back 🚀. Let's work together [`Get in touch`](https://crunchloop.io/#contact).

---

## 🎉 **Project Completion Summary**

This project successfully demonstrates:
- **Full-stack Rails development** with modern patterns
- **Real-time web applications** using Hotwire
- **Background job processing** with visual feedback
- **RESTful API design** with comprehensive testing
- **Container deployment** with Docker
- **Production-ready architecture** with proper separation of concerns

**Total Development Time**: Multiple phases of iterative development
**Key Achievement**: Zero-reload real-time progress tracking with individual task visualization

This file was updated by Angel Retali.