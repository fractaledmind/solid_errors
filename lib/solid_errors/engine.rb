# frozen_string_literal: true

module SolidErrors
  class Engine < ::Rails::Engine
    isolate_namespace SolidErrors

    config.solid_errors = ActiveSupport::OrderedOptions.new

    initializer "solid_errors.config" do
      config.solid_errors.each do |name, value|
        SolidErrors.public_send("#{name}=", value)
      end
    end

    initializer "solid_errors.active_record.error_subscriber" do
      Rails.error.subscribe(SolidErrors::Subscriber.new)
    end

    initializer "solid_errors.active_support.notification_subscriber" do
      ActiveSupport.on_load(:action_dispatch) do
        class ActionDispatch::Executor
          def call(env)
            returned = super

            if (exception = env['action_dispatch.exception'])
              @executor.error_reporter.report(exception, handled: false, source: "application.action_dispatch")
            end
            returned
          end
        end
      end
    end
  end
end
