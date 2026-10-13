module SolidErrors
  class ErrorMailerPreview < ActionMailer::Preview
    # Preview this email at http://localhost:3000/rails/mailers/solid_errors/error_mailer/error_occurred
    def error_occurred
      error = SolidErrors::Error.new(
        id: 3,
        exception_class: "Stack::Web::Api::Errors::MissingScope",
        message: "missing_scope",
        severity: "warning",
        source: "application",
        resolved_at: nil
      )

      occurrence = SolidErrors::Occurrence.new(
        id: 123,
        error: error,
        backtrace: sample_backtrace,
        context: {
          "Job" => "#<SyncMessageServiceChannelsJob>",
          "Request ID" => "abc123-def456",
          "User ID" => "42",
          "Environment" => "production"
        },
        created_at: 1.day.ago
      )

      SolidErrors::ErrorMailer.error_occurred(occurrence)
    end

    private

    def sample_backtrace
      [
        "[GEM_ROOT]/gems/slack-ruby-client-3.1.0/lib/slack/web/faraday/response/raise_error.rb:19:in `Slack::Web::Faraday::Response::RaiseError#on_complete'",
        "/rails/app/services/sync_message_service.rb:17:in `SyncMessageService#call'",
        "/rails/app/jobs/sync_message_service_channels_job.rb:5:in `SyncMessageServiceChannelsJob#perform'",
        "[GEM_ROOT]/gems/activejob-7.0.4/lib/active_job/execution.rb:48:in `ActiveJob::Execution#perform_now'",
        "[GEM_ROOT]/gems/activejob-7.0.4/lib/active_job/callbacks.rb:145:in `ActiveJob::Callbacks#perform_now'",
        "/rails/app/controllers/webhooks_controller.rb:23:in `WebhooksController#create'",
        "[GEM_ROOT]/gems/actionpack-7.0.4/lib/action_controller/metal/basic_implicit_render.rb:6:in `ActionController::Metal::BasicImplicitRender#send_action'",
        "[GEM_ROOT]/gems/actionpack-7.0.4/lib/abstract_controller/base.rb:215:in `AbstractController::Base#process_action'",
        "[GEM_ROOT]/gems/actionpack-7.0.4/lib/action_controller/metal/rendering.rb:53:in `ActionController::Metal::Rendering#process_action'",
        "[GEM_ROOT]/gems/railties-7.0.4/lib/rails/engine.rb:531:in `Rails::Engine#call'"
      ].join("\n")
    end
  end
end
