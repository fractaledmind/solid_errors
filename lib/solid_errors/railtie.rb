# frozen_string_literal: true

module SolidErrors
  class Railtie < ::Rails::Railtie
    initializer "solid_errors.active_record.error_subscriber" do
      Rails.error.subscribe(SolidErrors::Subscriber.new)
    end
  end
end
