Rails.application.routes.draw do
  devise_for :users
  root to: 'homes#top'
  resources :reviews, only: [:index, :create, :destroy]
  
end
