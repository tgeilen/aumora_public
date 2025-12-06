Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # API Routes
  namespace :api do
    namespace :v1 do
      match '*path', to: 'base#options', via: :options
      resources :users, only: [:show, :create, :update, :destroy]
      get 'users/current', to: 'users#current'
      
      # Email confirmation routes
      get 'confirmations', to: 'confirmations#show'
      post 'confirmations', to: 'confirmations#create'
      
      # Password reset routes
      post 'passwords', to: 'passwords#create'    # Request password reset
      put 'passwords', to: 'passwords#update'     # Reset password with token
      patch 'passwords', to: 'passwords#update'   # Alternative method for reset
      
      # User portfolios routes
      get 'users/current/portfolios', to: 'portfolios#index'
      
      # Portfolio routes with nested entries
      resources :portfolios do
        member do
          get 'holdings_breakdown'
          get 'etf_holdings_breakdown'
          get 'asset_holdings_breakdown'
          get 'total_holdings_exposure'
        end
        resources :entries, controller: 'portfolio_entries', only: [:create, :update, :destroy]
        resources :asset_entries, controller: 'portfolio_asset_entries'
      end
      
      # ETF routes
      resources :etfs, only: [:index, :show] do
        member do
          get 'holdings'
        end
      end
      
      # Asset routes
      resources :assets, only: [:index, :show]
      get 'overlapping_assets', to: 'assets#overlapping'
      
      # Authentication routes
      devise_scope :user do
        post 'login', to: 'sessions#create'
        delete 'logout', to: 'sessions#destroy'
      end

      match 'etfs/sync', to: 'etf_sync#sync', via: [:get, :post]
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  # Sidekiq web UI (protected in production)
  require 'sidekiq/web'
  require 'sidekiq/cron/web'
  
  # Protect Sidekiq web UI in production
  if Rails.env.production?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      # Use environment variables for basic auth
      ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch('SIDEKIQ_USERNAME', 'admin')) &&
      ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch('SIDEKIQ_PASSWORD', 'password'))
    end
  end
  
  mount Sidekiq::Web => '/sidekiq'

  # Serve frontend application
  get '*path', to: 'application#frontend', constraints: ->(request) { !request.xhr? && request.format.html? }
end
