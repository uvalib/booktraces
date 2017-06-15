Rails.application.routes.draw do
   get 'unauthorized' => "unauthorized#index"

   resources :listings, only: [:index]
   namespace :admin do
      resources :listings, only: [:index]
   end

   root :to => 'home#index'
   resources :home, only: [:index, :create]

   # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
