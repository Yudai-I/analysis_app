Rails.application.routes.draw do
  get 'homes/top'
  devise_for :users
  root to: 'reviews#index'
  resources :reviews, only: [:index, :create, :destroy]
  
end
