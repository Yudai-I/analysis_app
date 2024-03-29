Rails.application.routes.draw do
  devise_for :users
  root to: 'homes#top'
  post 'get_result_analysis' => 'reviews#get_result_analysis'
  resources :reviews, only: [:index, :create, :destroy] do
    resource :favorite, only: [:create, :destroy]
  end
  resources :users, only: [:index, :show]
end
