# frozen_string_literal: true

module SolidErrors
  class Engine < ::Rails::Engine
    isolate_namespace SolidErrors

    config.solid_errors = ActiveSupport::OrderedOptions.new

    initializer "solid_errors.config" do
      config.solid_errors.each do |name, value|
        SolidErrors.public_send(:"#{name}=", value)
      end

      if SolidErrors.send_emails? && !defined?(ActionMailer)
        raise "You have configured solid_errors.send_emails = true but ActionMailer is not available." \
              "Make sure that you require \"action_mailer/railtie\" in application.rb or set solid_errors.send_emails = false."
      end
    end

    initializer "solid_errors.active_record.error_subscriber" do
      Rails.error.subscribe(SolidErrors::Subscriber.new)
    end
  end
end
