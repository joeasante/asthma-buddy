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
      resources :dose_logs, only: %i[index create destroy]
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

  get "adherence", to: redirect("/preventer_history")
  get "preventer_history", to: "preventer_history#index", as: :preventer_history
  get "reliever-usage",  to: "reliever_usage#index",   as: :reliever_usage
  get "appointment-summary", to: "appointment_summaries#show", as: :appointment_summary
  get "dashboard", to: "dashboard#index", as: :dashboard

  scope :onboarding, as: :onboarding do
    get   "step/:step", to: "onboarding#show",    as: :step,  constraints: { step: /[12]/ }
    post  "step_1",    to: "onboarding#submit_1", as: :submit_1
    post  "step_2",    to: "onboarding#submit_2", as: :submit_2
    patch "skip/:step", to: "onboarding#skip",    as: :skip,  constraints: { step: /[12]/ }
  end

  resources :notifications, only: [ :index ] do
    member do
      patch :mark_read
    end
    collection do
      post :mark_all_read
    end
  end

  post "cookie-notice/dismiss", to: "cookie_notices#dismiss", as: :cookie_notice_dismiss

  get "privacy", to: "pages#privacy", as: :privacy
  get "terms",   to: "pages#terms",   as: :terms
  get "cookies", to: "pages#cookie_policy", as: :cookie_policy

  # Test-only route: signs a browser session in using a fixture session ID (sets signed cookie).
  # Only mounted in the test environment — never available in production.
  if Rails.env.test?
    get "test/sign_in/:session_id", to: "test/sessions#create", as: :test_sign_in
  end

  namespace :admin do
    root "dashboard#index"
    resources :users, only: [:index] do
      member do
        patch :toggle_admin
      end
    end
  end

  # Job monitoring UI — protected by HTTP Basic Auth (credentials: mission_control.http_basic_auth_*)
  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Defines the root path route ("/")
  root "home#index"

  match "/404", to: "errors#not_found",             via: :all
  match "/500", to: "errors#internal_server_error", via: :all
end
