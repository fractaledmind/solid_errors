SolidErrors::Engine.routes.draw do
  get "/", to: "errors#index", as: :root

  namespace :api, defaults: {format: :json} do
    resources :errors, only: [:index, :show, :update, :destroy]
  end

  resources :errors, only: [:index, :show, :update, :destroy], path: ""
end
