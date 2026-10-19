module SolidErrors
  class Subscriber
    IGNORED_ERRORS = ["ActionController::RoutingError",
      "AbstractController::ActionNotFound",
      "ActionController::MethodNotAllowed",
      "ActionController::UnknownHttpMethod",
      "ActionController::NotImplemented",
      "ActionController::UnknownFormat",
      "ActionController::InvalidAuthenticityToken",
      "ActionController::InvalidCrossOriginRequest",
      "ActionDispatch::Http::Parameters::ParseError",
      "ActionController::BadRequest",
      "ActionController::ParameterMissing",
      "ActiveRecord::RecordNotFound",
      "ActionController::UnknownAction",
      "ActionDispatch::Http::MimeNegotiation::InvalidType",
      "Rack::QueryParser::ParameterTypeError",
      "Rack::QueryParser::InvalidParameterError",
      "CGI::Session::CookieStore::TamperedWithCookie",
      "Mongoid::Errors::DocumentNotFound",
      "Sinatra::NotFound",
      "Sidekiq::JobRetry::Skip"].map(&:freeze).freeze

    def report(error, handled:, severity:, context:, source: nil)
      return if ignore_by_class?(error.class.name)

      error_attributes = {
        exception_class: error.class.name,
        message: s(error.message),
        severity: severity,
        source: source
      }
      fingerprint = Digest::SHA256.hexdigest(error_attributes.values.join)
      if (record = SolidErrors::Error.find_by(fingerprint: fingerprint))
        opens_error = :reopened if record.resolved?
        record.update!(resolved_at: nil, updated_at: Time.now)
      else
        opens_error = :created
        record = SolidErrors::Error.create!(error_attributes.merge(fingerprint: fingerprint))
      end

      SolidErrors::Occurrence.create(
        error_id: record.id,
        backtrace: error.backtrace&.join("\n"),
        context: s(readable_context(context)),
        opens_error: opens_error
      )
    end

    # Rails puts the current controller or job in the context; keep what identifies the work, not the object
    def readable_context(context)
      context = context.dup
      if defined?(ActionController::Metal) && (controller = context[:controller]).is_a?(ActionController::Metal)
        context[:controller] = "#{controller.class.name}##{controller.action_name}"
        context[:params] ||= controller.request.filtered_parameters.except("controller", "action") if SolidErrors.record_params
      end
      if defined?(ActiveJob::Base) && (job = context[:job]).is_a?(ActiveJob::Base)
        context[:job] = job.class.name
        context[:job_id] ||= job.job_id
        context[:queue] ||= job.queue_name
        context[:arguments] ||= parameter_filter.filter(arguments: s(job.arguments))[:arguments] if SolidErrors.record_arguments
      end
      context
    end

    def parameter_filter
      ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    end

    def s(data)
      Sanitizer.sanitize(data)
    end

    def ignore_by_class?(error_class_name)
      [*IGNORED_ERRORS, *SolidErrors.ignored_errors].any? do |ignored_class|
        ignored_class_name = ignored_class.respond_to?(:name) ? ignored_class.name : ignored_class

        ignored_class_name == error_class_name
      end
    end
  end
end
