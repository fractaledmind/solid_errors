module SolidErrors
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    http_basic_authenticate_with name: SolidErrors.username, password: SolidErrors.password if SolidErrors.password
  end
end
