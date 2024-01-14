SolidErrors::Engine.routes.draw do
  root to: "errors#index"

  resources :errors, only: [:index, :show, :update]
end
