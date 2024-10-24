Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: 'users/registrations' }

  get "documents/home"
  post "documents/query"

  resources :documents
  resources :folders

  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "documents#index"
end