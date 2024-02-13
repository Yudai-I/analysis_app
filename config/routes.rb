Rails.application.routes.draw do
  devise_for :users
  root to: 'homes#top'
  resources :reviews, only: [:index, :create, :destroy]
  resources :users, only: [:index, :show]
end
