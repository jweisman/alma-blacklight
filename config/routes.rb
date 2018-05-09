Rails.application.routes.draw do
  
  mount Blacklight::Engine => '/'
  Blacklight::Marc.add_routes(self)
  root to: "catalog#index"
    concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  get 'almaws/bibs/availability', to: 'almaws#availability'
  get 'almaws/bibs/:mms_id/holdings/:holding_id/items', to: 'almaws#items', as: 'almaws_items'
  get 'almaws/bibs/:mms_id/request-options', to: 'almaws#request_options'

  resource :articles, only: [:index] do
    concerns :searchable
  end

  match 'auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  get 'signout', to: 'sessions#destroy', as: 'destroy_user_session'
  get 'login', to: 'sessions#login', as: 'new_user_session'
  get 'edit_user_registration', to: 'card#show', as: 'edit_user_registration'

  resource :card, only: [:show], controller: 'card' do
    collection do
      get 'fines'
      resources :requests, only: [:index, :new, :create, :destroy], controller: 'card/requests'
    end
  end

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
    end
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
