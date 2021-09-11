Rails.application.routes.draw do
  resources :contacts do
    get 'search', to: 'contacts#search', on: :collection
  end
  resources :deals do
    resources :notes, module: :deals
    resources :activities, module: :deals
    resources :flow_items, only: [:destroy], module: :deals
  end

  resources :pipelines
  devise_for :users
  root to: "pipelines#index"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
