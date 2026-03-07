# frozen_string_literal: true
Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[ new create ]
  get "email_verification/new", to: "email_verifications#new", as: :new_email_verification
  post "email_verification", to: "email_verifications#create", as: :email_verification_resend
  get "email_verification/:token", to: "email_verifications#show", as: :email_verification
  resources :passwords, param: :token, only: %i[ new create edit update ]
  resources :symptom_logs, path: "symptom-logs", only: %i[ index create edit update destroy ]
  resources :peak_flow_readings, path: "peak-flow-readings", only: %i[ new create index ]

  get  "settings",               to: "settings#show",                as: :settings
  post "settings/personal_best", to: "settings#update_personal_best", as: :settings_personal_best

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # CSP violation reports from browsers (report-only mode).
  post "/csp-violations", to: "csp_reports#create"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
