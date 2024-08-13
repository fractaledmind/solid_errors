SolidErrors::Engine.routes.draw do
  get "/" => "errors#index", :as => :root

  resources :errors, only: [:index, :show, :update, :destroy], path: "" do
    collection do
      get :resolved
    end
  end
end
