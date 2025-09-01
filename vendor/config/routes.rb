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
  
  root 'todo_lists#index'
end
