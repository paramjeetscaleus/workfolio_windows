Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :admins
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  
  match '/logout(/:id)', to: "users#destroy", as: "user_logout", via: [:get, :delete]
  get "new_signup/" , to: "users#new_signup" , as: "new_signup"
  post "user_signup/" , to: "users#user_signup" , as: "user_signup"
  get "login/" , to: "users#new_login" , as: "login"
  post "login/" , to: "users#user_login" , as: "user_login"
  get "activity/" , to: "users#activity" , as: "activity"
  
  root "users#index"

  get "index", to: "work_sessions#index", as: "work_session_index"
  post "clock_in", to: "work_sessions#clock_in", as: "clock_in_work_sessions"
  post "start_break", to: "work_sessions#start_break", as: "start_break_work_sessions"
  post "end_break", to: "work_sessions#end_break", as: "end_break_work_sessions"
  post "clock_out", to: "work_sessions#clock_out", as: "clock_out_work_sessions"
  get 'work_sessions/:id/user_work_session_report', to: 'work_sessions#user_work_session_report', as: 'user_report'

  post 'screenshots/create_from_python', to: 'screenshots#create_from_python'
  # resources :screenshots, only: [:index, :show]
  # resources :screenshots, only: [:index, :show, :destroy]

  # namespace :api do
  #   resources :screenshots, only: [:create]
  # end  
end
