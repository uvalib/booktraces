Rails.application.routes.draw do
   get 'unauthorized' => "unauthorized#index"

   resources :listings, only: [:index, :show]
   namespace :admin do
      resources :listings, only: [:index, :show]
   end

   namespace :api do
      get 'search' => 'listings#search'
      get 'detail/:id' => 'listings#detail'
      post 'query' => 'listings#query'
      get 'search_state' => 'listings#search_state'
   end

   root :to => 'home#index'
   resources :home, only: [:index, :create]

   # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
