Rails.application.routes.draw do
  root "pages#home"

  # AI 이미지 분석 API
  post '/analyze_image', to: 'analysis#analyze_image'
  get '/check_analysis_count', to: 'analysis#check_analysis_count'

  # 사전예약 API
  post '/pre_orders', to: 'pre_orders#create'
  
  # 버튼 클릭 추적 API
  post '/button_clicks', to: 'button_clicks#create'

  # 관리자 인증
  get '/admin/login', to: 'admin#login', as: 'admin_login'
  post '/admin/login', to: 'admin#login'
  delete '/admin/logout', to: 'admin#logout', as: 'admin_logout'
  get '/admin/dashboard', to: 'admin#dashboard'

  # 데이터 다운로드
  get '/admin/download_pre_orders', to: 'admin#download_pre_orders', as: 'admin_download_pre_orders'

  # 데이터 삭제
  delete '/admin/pre_orders/:id', to: 'admin#destroy_pre_order'
  delete '/admin/pre_orders', to: 'admin#destroy_all_pre_orders', as: 'admin_pre_orders'
  delete '/admin/button_clicks/:id', to: 'admin#destroy_button_click', as: 'admin_button_click'
  delete '/admin/button_clicks', to: 'admin#destroy_all_button_clicks', as: 'admin_button_clicks'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
end
