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

    # This is a hack that I hate, but it's the only way to get the error reporter
    # to report exceptions in production. Currently, Rails _renders_ production errors,
    # but doesn't _raise_ them, and the `Executor` only reports raised exceptions.
    # So, this monkey-patch ensures to report any logged exceptions.
    initializer "solid_errors.active_support.notification_subscriber" do
      ActiveSupport.on_load(:action_dispatch_request) do
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
