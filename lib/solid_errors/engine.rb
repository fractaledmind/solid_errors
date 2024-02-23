# frozen_string_literal: true

module SolidErrors
  class Engine < ::Rails::Engine
    isolate_namespace SolidErrors

    config.solid_errors = ActiveSupport::OrderedOptions.new

    initializer "solid_errors.config" do
      config.solid_errors.each do |name, value|
        SolidErrors.public_send(:"#{name}=", value)
      end
    end

    initializer "solid_errors.active_record.error_subscriber" do
      Rails.error.subscribe(SolidErrors::Subscriber.new)
    end
  end
end
