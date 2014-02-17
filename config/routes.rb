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

  resources :program_events do
    collection do
      get :reductions
    end
    member do
      post :multiply_field
    end
  end

  resources :program_entry_people
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
    end
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
    end
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
    end
    resources :person_pictures, path: 'images'
  end
  resources :person_pictures
  
  resources :ensemble_people

  resources :program_files


end
