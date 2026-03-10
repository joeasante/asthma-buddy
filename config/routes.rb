# frozen_string_literal: true

Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[ new create ]
  get "email_verification/new", to: "email_verifications#new", as: :new_email_verification
  post "email_verification", to: "email_verifications#create", as: :email_verification_resend
  get "email_verification/:token", to: "email_verifications#show", as: :email_verification
  resources :passwords, param: :token, only: %i[ new create edit update ]
  resources :symptom_logs, path: "symptom-logs", only: %i[ index new create show edit update destroy ]
  resources :peak_flow_readings, path: "peak-flow-readings", only: %i[ new create index show edit update destroy ]
  resources :health_events, path: "medical-history", only: %i[ index new create show edit update destroy ]

  resource :profile, only: %i[show update]
  post "profile/personal_best", to: "profiles#update_personal_best", as: :profile_personal_best
  delete "profile/avatar", to: "profiles#remove_avatar", as: :profile_avatar

  get "settings", to: "settings#show", as: :settings

  scope "/settings", module: :settings, as: :settings do
    resource :account, only: [ :destroy ]
    resources :medications, only: %i[index new create edit update destroy] do
      member do
        patch :refill
      end
      resources :dose_logs, only: %i[create destroy]
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # CSP violation reports from browsers (report-only mode).
  post "/csp-violations", to: "csp_reports#create"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "adherence",       to: "adherence#index",        as: :adherence
  get "reliever-usage",  to: "reliever_usage#index",   as: :reliever_usage
  get "dashboard", to: "dashboard#index", as: :dashboard

  scope :onboarding, as: :onboarding do
    get   "step/:step", to: "onboarding#show",    as: :step,  constraints: { step: /[12]/ }
    post  "step_1",    to: "onboarding#submit_1", as: :submit_1
    post  "step_2",    to: "onboarding#submit_2", as: :submit_2
    patch "skip/:step", to: "onboarding#skip",    as: :skip,  constraints: { step: /[12]/ }
  end

  post "cookie-notice/dismiss", to: "cookie_notices#dismiss", as: :cookie_notice_dismiss

  get "privacy", to: "pages#privacy", as: :privacy
  get "terms",   to: "pages#terms",   as: :terms

  # Defines the root path route ("/")
  root "home#index"
end
