SolidErrors::Engine.routes.draw do
  get "/" => "errors#index", as: :root

  resources :errors, only: [:index, :show, :update], path: ""
end
