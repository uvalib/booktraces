Rails.application.routes.draw do
   get 'unauthorized' => "unauthorized#index"

   resources :listings, only: [:index, :show]
   namespace :admin do
      resources :listings, only: [:index, :show, :update]
      resources :interventions, only: [:create, :update, :destroy]
      resources :destinations, only: [:create, :update, :destroy]
   end

   namespace :api do
      get 'classifications/:id' => 'api#classifications'
      get 'subclassifications/:id' => 'api#subclassifications'
      get 'search' => 'api#search'
      get 'detail/:id' => 'api#detail'
      post 'query' => 'api#query'
      get 'search_state' => 'api#search_state'
   end

   root :to => 'home#index'
   resources :home, only: [:index, :create]

   # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
