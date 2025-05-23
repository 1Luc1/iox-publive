Iox::Engine.routes.draw do

  resources :program_entries do
    member do
      get :crew_of
      get :events_for
      get :images_for
      post :upload_image
      post :download_image_from_url
      post :order_images
      post :order_crew
      post :finish
      put :publish
      get  :settings_for
      post :restore
    end
    collection do
      get :find_conflicting_names
      get :festivals
    end
  end
  resources :program_entry_events

  resources :premieres

  resources :syncers do
    member do
      get :sync
      get :now
      get :settings_for
    end
  end

  resources :program_events do
    collection do
      get :reductions
    end
    member do
      post :multiply_field
    end
  end

  resources :program_entry_people

  resources :instagram_posts

  resources :ensembles do
    member do
      post :upload_logo
      get  :members_of
      get  :settings_for
      post :restore
      post :download_image_from_url
      post :order_images
    end
    collection do
      get :simple
      get :merge
      get :clean
      get :merged
    end
    post :clean_selected, :on => :collection
    post :merge_selected, :on => :collection
    resources :ensemble_pictures, path: 'images'
  end
  resources :ensemble_pictures

  resources :venues do
    member do
      post :upload_logo
      get  :settings_for
      post :restore
      get :images_for
      post :upload_image
      post :download_image_from_url
    end
    collection do
      get :simple
      get :merge
      get :clean
      get :merged
    end
    post :clean_selected, :on => :collection
    post :merge_selected, :on => :collection
    resources :venue_pictures, path: 'images'
  end
  resources :venue_pictures
  
  resources :people do
    member do
      post :upload_avatar
      get  :settings_for
      post :restore
      get :images_for
      post :upload_image
      post :download_image_from_url
      post :order_images
    end
    collection do
      get :simple
      get :merge
      get :clean
      get :merged
    end
    post :clean_selected, :on => :collection
    post :merge_selected, :on => :collection
    resources :person_pictures, path: 'images'
  end
  resources :person_pictures
  
  resources :ensemble_people

  resources :program_files

  resources :tags do
    collection do
      get :simple
    end
  end


end
