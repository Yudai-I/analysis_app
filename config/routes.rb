Rails.application.routes.draw do
  get 'reviews/new' => 'reviews#new'
  resources :reviews, only: [:index, :create, :destroy]
end
