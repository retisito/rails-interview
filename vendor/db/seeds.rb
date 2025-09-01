# Create TodoLists
todo_list_1 = TodoList.create(name: 'Setup Rails Application')
todo_list_2 = TodoList.create(name: 'Setup Docker PG database')
todo_list_3 = TodoList.create(name: 'Create todo_lists table')
todo_list_4 = TodoList.create(name: 'Create TodoList model')
todo_list_5 = TodoList.create(name: 'Create TodoList controller')

# Create TodoItems for each TodoList
todo_list_1.todo_items.create([
  { description: 'Initialize new Rails application', completed: true },
  { description: 'Configure Gemfile dependencies', completed: true },
  { description: 'Setup basic folder structure', completed: false }
])

todo_list_2.todo_items.create([
  { description: 'Install Docker', completed: true },
  { description: 'Create docker-compose.yml', completed: false },
  { description: 'Configure PostgreSQL container', completed: false }
])

todo_list_3.todo_items.create([
  { description: 'Create migration file', completed: true },
  { description: 'Define table schema', completed: true },
  { description: 'Run rails db:migrate', completed: true }
])

todo_list_4.todo_items.create([
  { description: 'Create TodoList model file', completed: true },
  { description: 'Add validations', completed: true },
  { description: 'Add associations', completed: false }
])

todo_list_5.todo_items.create([
  { description: 'Generate controller', completed: true },
  { description: 'Implement index action', completed: true },
  { description: 'Implement create action', completed: false },
  { description: 'Add API endpoints', completed: false }
])