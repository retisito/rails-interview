require 'sidekiq/web'

Rails.application.routes.draw do
  # Sidekiq Web UI (mount in development and staging only for security)
  mount Sidekiq::Web => '/sidekiq' if Rails.env.development? || Rails.env.staging?
  
  # Action Cable for Turbo Streams
  mount ActionCable.server => '/cable'
  
  namespace :api do
    resources :todo_lists, only: %i[index create show update destroy], path: :todolists do
      resources :todo_items, path: :todos
      member do
        post :auto_complete
      end
    end
    
    # Jobs management endpoints
    resources :jobs, only: [] do
      collection do
        get :stats
        get :queues
      end
      member do
        post :cancel
      end
    end
  end

  resources :todo_lists, path: :todolists do
    resources :todo_items do
      member do
        patch :toggle
      end
    end
    
    # Progressive completion routes
    member do
      post :start_progressive_completion
      get :progress
      get :test_cable
    end
  end
  
  # Sync Dashboard routes - Implementación del Plan de Acción Crunchloop
  get 'sync_dashboard', to: 'sync_dashboard#index'
  get 'sync_dashboard/sessions', to: 'sync_dashboard#sessions'
  get 'sync_dashboard/conflicts', to: 'sync_dashboard#conflicts'
  get 'sync_dashboard/stats', to: 'sync_dashboard#stats'
  get 'sync_dashboard/api_health', to: 'sync_dashboard#api_health'
  
  post 'sync_dashboard/trigger_sync/:todo_list_id', to: 'sync_dashboard#trigger_sync', as: :sync_dashboard_trigger_sync
  post 'sync_dashboard/enable_sync/:todo_list_id', to: 'sync_dashboard#enable_sync', as: :sync_dashboard_enable_sync
  post 'sync_dashboard/disable_sync/:todo_list_id', to: 'sync_dashboard#disable_sync', as: :sync_dashboard_disable_sync
  post 'sync_dashboard/resolve_conflict/:conflict_id', to: 'sync_dashboard#resolve_conflict', as: :sync_dashboard_resolve_conflict
  post 'sync_dashboard/auto_resolve_conflicts', to: 'sync_dashboard#auto_resolve_conflicts', as: :sync_dashboard_auto_resolve_conflicts
  
  root 'todo_lists#index'
end
