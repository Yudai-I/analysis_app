Rails.application.routes.draw do
  devise_for :users
  resources :reviews, only: [:index, :create, :destroy]
end
